require 'rubygems'
require 'optparse' 
require 'plcutil/wonderware/intouchfile'

module PlcUtil
  class IntouchPrettyPrintRunner
    def initialize(arguments)
      # Standard options
      @mode = :io

      # Parse command line options
			option_parser.parse! arguments
			if arguments.size > 1
				show_help
				exit
			end
      filename, = arguments



      # Read from intouch file
      @intouch_file = IntouchFile.new
			if filename
				File.open filename do |f|
					@intouch_file.read_csv f
				end
			else
        @intouch_file.read_csv $stdin
			end

      # print the tags in intouch
      case @mode
      when :io
        print_io
      when :alarm_groups
        print_alarm_groups
      when :access_names
        print_access_names
      when :tag
        print_tag @tag
      end
    end


    def print_io
      ss = %w( :IODisc :IOReal :IndirectAnalog :MemoryReal :IOMsg :IndirectMsg 
                :MemoryMsg :MemoryDisc :IndirectDisc :IOInt :MemoryInt)
      tags = []
      ss.each {|section| @intouch_file.each_tag(section) {|tag| tags << tag } }

      columns = []
      columns << {:max => 1, :min => 1, :nospace => true, :gen => Proc.new { |tag| alarm_icon(tag) } }
      columns << {:max => 50, :min => 15, :gen => lambda {|tag| tag.tag } }
      columns << {:max => 20, :min => 10, :gen => Proc.new {|tag| get_tag_field(:item_name, tag) } }
      columns << {:max => 20, :min => 10, :gen => Proc.new {|tag| get_tag_field(:access_name, tag) } }
      columns << {:rest => true, :gen => Proc.new {|tag| comment_for_tag(tag) } }

      # shrink columns
      columns.each do |c| 
        if c[:max]
          c[:adjusted] = max_str_len(tags, c[:max], c[:min]) {|tag| c[:gen].call(tag) }
        end
      end

      # use remaining space for :rest tag
      spaces = columns.map {|c| c[:nospace] ? 0 : 1 }.reduce(:+) - 1
      wasted = columns.map {|c| c[:adjusted] || 0 }.reduce(:+) - spaces
      rest = columns.find {|c| c[:rest] }
      @column_width ||= console_width
      rest[:adjusted] = @column_width - wasted if rest

      first_columns = columns - [columns.last]
      tags.each do |tag|
        cs = first_columns.map do |c| 
          fix_string(c, tag).ljust(c[:adjusted]) + (c[:nospace] ? '' : ' ') 
        end
        cs << fix_string(columns.last, tag)
        str = cs.join
        str = yellow(str) if tag.alarm?
        puts str
      end
		end

    def max_str_len(tags, abs_max, abs_min) 
      [abs_max, tags.reduce(abs_min) {|max, tag| max = [max, (yield tag).size].max }].min
    end



    def get_tag_field(field, tag)
      if tag.respond_to? field
        tag.method(field).call || ''
      else
        ''
      end
    end

    def fix_string(column, tag)
      str = column[:gen].call(tag)
      if str.size > column[:adjusted]
        str[0..(column[:adjusted] - 4)] + '...'
      else
        str
      end
    end


    def print_alarm_groups
      print_four_column_tags ':AlarmGroup'
    end

    def print_access_names
      print_four_column_tags ':IOAccess'
    end

    def print_four_column_tags(section)
      lines = []
      @intouch_file.each_tag section do |tag|
        lines << tag.tag
      end
      lines.each_slice(4) do |slice|
        slice[3] ||= nil
        puts ('%-20s' * 4) % slice
      end
    end

    def print_tag(tag)
      t = @intouch_file.find_tag(tag)
      if t
        puts 'Tag: ' + tag
        t.intouch_fields.each do |field|
          puts '%-30s%s' % [field.to_s, t.method(field).call]
        end
      else
        puts 'Tag %s was not found' % tag
      end
    end

		def option_parser
			OptionParser.new do |opts|
				opts.banner = "Usage: intouchreader [options] [DBFILE]"
				opts.on("-c", "--access-names", "Show access name") do
          @mode = :access_names
				end
				opts.on("-t", "--tag TAGNAME", "Show all fields for the specified tag") do |tag|
          @mode = :tag
          @tag = tag
				end
				opts.on("-w", "--wide", "Print wider than console width") do
          @column_width = 9999
				end
				opts.on("-a", "--alarm-groups", "Show alarm groups") do
          @mode = :alarm_groups
				end
				opts.on_tail("-h", "--help", "Show this message") do
					puts opts
          puts ''
          puts 'TIP: install ncurses gem to let intouchpp use full console width'
					exit
				end
			end	
		end
		
		def show_help
			puts option_parser
		end  

    private

    def console_width
      result = 80
      if require 'ncurses'
        Ncurses.initscr
        begin
          result = Ncurses.COLS - 6 #???
        ensure
          Ncurses.endwin
        end
      end
    end

    def comment_for_tag(tag)
      if tag.alarm? 
        tag.alarm_comment
      else
        tag.comment
      end || ''
    end

    def alarm_icon(tag)
      if tag.alarm? 
        '*'
      else
        ' '
      end
    end

    def colorize(text, color_code)
      "#{color_code}#{text}\e[0m"
    end

    def yellow(text)
      colorize text, "\e[33m"
    end

    def red(text)
      colorize text, "\e[31m"
    end

    def green(text)
      colorize text, "\e[32m"
    end

  end
end

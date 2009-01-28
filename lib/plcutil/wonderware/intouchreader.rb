require 'optparse' 
require 'plcutil/wonderware/intouchfile'

module PlcUtil
  class IntouchReader
    def initialize
      # Standard options
      @mode = :io

      # Parse command line options
			option_parser.parse! ARGV
			if ARGV.size > 1
				show_help
				exit
			end
      filename, = ARGV



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
      ss.each do |section|
        @intouch_file.each_tag section do |row|
          puts '%s%-33s%-20s%-20ss%s' % [
            (row.respond_to?(:alarm_state) && row.alarm_state && row.alarm_state.match(/None/)) ? ' ' : '*', 
            row.tag, 
            row.respond_to?(:item_name) ? row.item_name : '',
            row.access_name, 
            row.comment
          ]
        end
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
      puts 'Tag: ' + tag
      @intouch.find_tag(tag).intouch_fields.collect do |field|
        [field.to_s, row.method(field).call]
      end.each do |pair|
        puts '%-20s%s' % pair
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
				opts.on("-a", "--alarm-groups", "Show alarm groups") do
          @mode = :alarm_groups
				end
				opts.on_tail("-h", "--help", "Show this message") do
					puts opts
					exit
				end
			end	
		end
		
		def show_help
			puts option_parser
		end  end

  IntouchReader.new
end


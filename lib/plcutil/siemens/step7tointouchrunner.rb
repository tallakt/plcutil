#!/usr/bin/ruby

require 'optparse'
require 'plcutil/siemens/awlfile'
require 'plcutil/wonderware/intouchfile'

module PlcUtil
	# Command line tool to read and output an awl file
	class Step7ToIntouchRunner
		def initialize(command_line_arguments)
      # standard command line options
			@awloptions = {}
			@intouchoptions = {}
			@output = nil
			@symlistfile = nil
      @no_block = false
      @access_name = nil
      @filter_file = nil

      # Parse command line options
			option_parser.parse! command_line_arguments
			if command_line_arguments.empty?
				show_help
				exit
			end

      # Read Siemens S7 file
			@awllist = command_line_arguments.map{|filename| AwlFile.new filename, @awloptions}

      # create a lookup table for used tags in the file to prevent duplicate ids
      @used_tags = {}
      @awllist.each do |awl|
        awl.each_tag do |tag, addr, comment, type|
          @used_tags[siemens_to_ww_tagname_long tag] = true
        end
      end

      # load filter file to enable override of functions filter_comment_format and filter_handle_tag
      load @filter_file if @filter_file && File.exists?(@filter_file)

      # Write to intouch file
			if @output
				File.open @output, 'w' do |f|
					print_to_file f
				end
			else
				print_to_file $stdout
			end
		end
		
    # This function may be overriden in filter ruby file
    def filter_comment_format(comment, struct_comment)
      if comment || struct_comment
        [comment, struct_comment].compact.join(' / ').gsub(/"/, '')
      else
        ''
      end
    end

    # This function may be overridden in filter ruby file
    def filter_handle_tag(name, addr, comment, struct_comment, type, intouch_file)
      ww_name = siemens_to_ww_tagname name
      cc = filter_comment_format comment, struct_comment
      case type
        when :bool
          intouch_file.new_io_disc(ww_name) do |io|
            io.item_name = addr
            io.comment = cc
          end
        when :int
          intouch_file.new_io_int(ww_name) do |io|
            io.item_name = addr
            io.comment = cc
          end
        when :real
          intouch_file.new_io_real(ww_name) do |io|
            io.item_name = addr
            io.comment = cc
          end
        else
          throw RuntimeError.new 'Unsupported type found: ' + type.to_s
      end
     end


    # This function may be overridden in filter ruby file
    def filter_handle_awl_files
      @awllist.each do |awl|
        awl.each_tag do |name, addr, comment, struct_comment, type|
          filter_handle_tag name, addr, comment, struct_comment, type, @intouchfile
        end
      end
    end


		def print_to_file(f)
      @intouchfile = IntouchFile.new nil, @intouchoptions
      filter_handle_awl_files
      i.write_csv f
		end

    def siemens_to_ww_tagname(s)
      new_unique_tag(siemens_to_ww_tagname_long s)
    end

    def siemens_to_ww_tagname_long(s)
      if @no_block
        s.gsub /^[^\.]*./, ''
      else
        s
      end.gsub(/\./, '_').gsub(/\[(\d+)\]/) { '_' + $1 }
    end

    def new_unique_tag_helper(s, n)
      s[0..(31 - n.to_s.size - 1)] + '%' + n.to_s
    end

    def new_unique_tag(s)
      if s.size < 33
        s
      else
        n = nil
        new_tag = new_unique_tag_helper s, n
        while @used_tags.key? new_tag
          n ||= 0
          n += 1
          new_tag = new_unique_tag_helper s, n
        end
        @used_tags[new_tag] = true
        new_tag
      end
    end

		def option_parser
			OptionParser.new do |opts|
				opts.banner = "Usage: s7tointouch [options] AWLFILE [AWLFILE ...]"
				opts.on("-s", "--symlist FILE", String, "Specify SYMLIST.DBF file from S7 project ") do |symlistfile|
					@awloptions[:symlist] = symlistfile
				end
				opts.on("-n", "--no-block", String, "Dont use the datablock as part of the tag", "name") do
					@no_block = true
				end
				opts.on("-b", "--block NAME=ADDR", String, "Define address of datablock without", "reading ymlist") do |blockdef|
					name, addr = blockdef.split(/=/)
					@awloptions[:blocks] ||= {}
					@awloptions[:blocks][name] = addr
				end
				opts.on("-a", "--access ACCESSNAME", String, "Set access name for all tags") do |access_name|
          @intouchoptions[:access_name] = access_name
				end
				opts.on("-f", "--filter FILTER_RUBY_FILE", String, "Specify ruby filter file to override", "filter functions") do |filter_file|
					@filter_file = filter_file
				end
				opts.on("-o", "--output FILE", String, "Output to specified file instead of", "standard output") do |output|
					@output = output
				end
				opts.on_tail("-h", "--help", "Show this message") do
					puts opts
					exit
				end
			end	
		end
		
		def show_help
			puts option_parser
		end
	end
end


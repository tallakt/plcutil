#!/usr/bin/ruby

require 'optparse'
require 'plcutil/siemens/awlfile'
require 'plcutil/siemens/sdffile'
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

      # Read Siemens S7 files
      # AWL - generated by using 'generate source' and selecting a DB
      # SDF - export file generated from variable list and selecting 'export'
      awl_files = command_line_arguments.select {|fn| fn.match(/\.awl$/i) }
      sdf_files = command_line_arguments - awl_files
			@sdflist = sdf_files.map{|filename| SdfFile.new filename }
			@awllist = awl_files.map{|filename| AwlFile.new filename, @awloptions}

      # create a lookup table for used tags in the file to prevent duplicate ids
      # TODO Move this into Intouchfile class
      @used_tags = {}
      
      @sdflist.each do |sdf|
        sdf.tags.each do |tag|
          @used_tags[siemens_to_ww_tagname_long tag.tagname] = true
        end
      end

      @awllist.each do |awl|
        awl.each_tag do |tag, data_block_name, addr, comment, istruct_comment, type|
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

    def format_addr(addr, ww_tag, is_bool = false)
      case addr
      when String
        addr.gsub /\s/, '' # from symbol list file, ww accepts addres directly
      else
        db = addr.data_block_addr || 'DB???'
        db + ',' + ww_tag + addr.byte.to_s + (is_bool ? ('.' + addr.bit.to_s) : '')
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
    def filter_handle_tag(name, datablock_name, addr, comment, struct_comment, type)
      ww_name = siemens_to_ww_tagname name
      cc = filter_comment_format comment, struct_comment
      created_io = case type
        when :bool
          @intouchfile.new_io_disc(ww_name) do |io|
            io.item_name = format_addr(addr, 'X', true)
            io.comment = cc
          end
        when :int
          @intouchfile.new_io_int(ww_name) do |io|
            io.item_name = format_addr(addr, 'INT')
            io.comment = cc
          end
        when :word
          @intouchfile.new_io_int(ww_name) do |io|
            io.item_name = format_addr(addr, 'WORD')
            io.comment = cc
          end
        when :real
          @intouchfile.new_io_real(ww_name) do |io|
            io.item_name = format_addr(addr, 'REAL')
            io.comment = cc
          end
        when :byte
          @intouchfile.new_io_int(ww_name) do |io|
            io.item_name = format_addr(addr, 'BYTE')
            io.comment = cc
          end
        when :char
          @intouchfile.new_io_int(ww_name) do |io|
            io.item_name = format_addr(addr, 'CHAR')
            io.comment = cc
          end
        when :date, :s5time, :time_of_day, :timer
          # skip
        when :dint
          @intouchfile.new_io_int(ww_name) do |io|
            io.item_name = format_addr(addr, 'DINT')
            io.comment = cc
          end
        when :dword, :time
          @intouchfile.new_io_int(ww_name) do |io|
            io.item_name = format_addr(addr, 'DWORD')
            io.comment = cc
          end
        else
          throw RuntimeError.new 'Unsupported type found: ' + type.to_s
      end
      yield created_io if block_given?
     end


    # This function may be overridden in filter ruby file
    def filter_handle_sdf_files
      @sdflist.each do |sdf|
        sdf.tags.each do |tag|
          filter_handle_tag tag.tagname, '', tag.addr, tag.comment, nil, tag.datatype
        end
      end
    end

    # This function may be overridden in filter ruby file
    def filter_handle_awl_files
      @awllist.each do |awl|
        awl.each_tag do |name, datablock_name, addr, comment, struct_comment, type|
          filter_handle_tag name, datablock_name, addr, comment, struct_comment, type
        end
      end
    end



		def print_to_file(f)
      @intouchfile = IntouchFile.new nil, @intouchoptions
      filter_handle_sdf_files
      filter_handle_awl_files
      @intouchfile.write_csv f
		end

    def siemens_to_ww_tagname(s)
      new_unique_tag(siemens_to_ww_tagname_long s)
    end

    def siemens_to_ww_tagname_long(s)
      if @no_block
        s.gsub /^[^\.]*./, ''
      else
        s
      end.gsub(/[\. ]/, '_').gsub(/\[(\d+)\]/) { '_' + $1 }
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
				opts.banner = "Usage: s7tointouch [options] <.awl or .sdf files>"
				opts.on("-s", "--symlist FILE", String, "Specify SYMLIST.DBF file from S7 project ") do |symlistfile|
					@awloptions[:symlist] = symlistfile
				end
				opts.on("-n", "--no-block", String, "Dont use the datablock as part of the tag", "name") do
					@no_block = true
				end
				opts.on("-b", "--block NAME=ADDR", String, "Define address of datablock without", "reading symlist") do |blockdef|
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


#!/usr/bin/ruby

require 'optparse'
require 'plcutil/siemens/awlfile'
require 'plcutil/wondeware/intouchfile'

module PlcUtil
	# Command line tool to read and output an awl file
	class AwlToIntouch
		def initialize
			@awloptions = {}
			@output = nil
			@symlistfile = nil
			option_parser.parse! ARGV
			if ARGV.size != 1
				show_help
				exit
			end
			filename, = ARGV
			@awl = AwlFile.new filename, @awloptions
			if @output
				File.open @output, 'w' do |f|
					print_to_file f
				end
			else
				print_to_file $stdout
			end
		end
		

		def print_to_file(f)
      i = IntouchFile.new
			@awl.each_tag do |name, addr, comment, type|
        case type
          when :bool
            i.new_io_disc(name) do |io|
              io.item_name = addr
              io.comment = comment
            end
          when :int
            i.new_io_int(name) do |io|
              io.item_name = addr
              io.comment = comment
            end
          when :real
            i.new_io_real(name) do |io|
              io.item_name = addr
              io.comment = comment
            end
          else
            throw 'Unsupported type found: ' + type.to_s
          end
        end
			end
      i.write_csv f
		end
		
		def option_parser
			OptionParser.new do |opts|
				opts.banner = "Usage: awltointouch [options] AWLFILE"
				opts.on("-s", "--symlist FILE", String, "Specify SYMLIST.DBF file from S7 project ") do |symlistfile|
					@awloptions[:symlist] = symlistfile
				end
				opts.on("-b", "--block NAME=ADDR", String, "Define address of datablock without reading symlist") do |blockdef|
					name, addr = blockdef.split(/=/)
					@awloptions[:blocks] ||= {}
					@awloptions[:blocks][name] = addr
				end
				opts.on("-o", "--output FILE", String, "Output to specified file instead of standard output") do |output|
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

PlcUtil::AwlToIntouch.new



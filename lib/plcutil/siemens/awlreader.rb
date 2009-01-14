#!/usr/bin/ruby

require 'optparse'
require 'plcutil/siemens/awlfile'

module PlcUtil
	# Command line tool to read and output an awl file
	class AwlReader
		def initialize
			@awloptions = {}
			@format = '%-11s %-40s%-10s%s'
			@commentformat = '# %s'
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
			@awl.each_tag do |name, addr, comment, type|
				f.puts @format % [addr, name, type.to_s, comment ? @commentformat % comment : '']
			end
		end
		
		def option_parser
			OptionParser.new do |opts|
				opts.banner = "Usage: awlreader [options] AWLFILE"
				opts.on("-c", "--csv", String, "Output as CSV file") do
					format = '%s;%s;%s;%s' 
					@commentformat = '%s'
				end
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

PlcUtil::	AwlReader.new



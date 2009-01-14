#!/usr/bin/ruby

require 'optparse'
require 'plcutil/siemens/awlfile'

# Command line tool to read and output an awl file
class AwlReader
	def initialize
		@format = '%-11s %-40s%s'
		@commentformat = '# %s'
		@output = nil
		@symlistfile = nil
		option_parser.parse! ARGV
		if ARGV.size != 1
			show_help
			exit
		end
		filename, = ARGV
		@awl = AwlFile.new filename, @symlistfile
		if @output
			File.open @output, 'w' do |f|
				print_to_file f
			end
		else
			print_to_file $stdout
		end
	end
	

	def print_to_file(f)
		@awl.each_tag do |name, addr, comment|
			f.puts @format % [addr, name, comment ? @commentformat % comment : '']
		end
	end
	
	def option_parser
		OptionParser.new do |opts|
			opts.banner = "Usage: awlreader [options] AWLFILE"
			opts.on("-c", "--csv", String, "Output as CSV file") do
				@format = '%s;%s;%s' 
				@commentformat = '%s'
			end
			opts.on("-s", "--symlist FILE", String, "Specify SYMLIST.DBF file from S7 project ") do |symlistfile|
				@symlistfile = symlistfile
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

AwlReader.new



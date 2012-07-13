#!/usr/bin/ruby
#encoding: utf-8

require 'optparse'
require 'tallakt-plcutil/wonderware/intouchfile'
require 'ostruct'

module PlcUtil
	# Command line tool to read and output an awl file
	class PL7ToIntouchRunner
		def initialize(command_line_arguments)
      # standard command line options
			@intouchoptions = {}
			@output = nil
			@input = nil
			@symlistfile = nil
      @access_name = nil
      @pl7_tags = []
      @prefix = nil
      @alarm = false
      @caps = false
      @alarm_group = '$System'

      # Parse command line options
			option_parser.parse! command_line_arguments


			if @input
				File.open @input do |f|
					read_pl7_file f
				end
			else
				read_pl7_file $stdin
			end

      # Write to intouch file
			if @output
				File.open @output, 'w' do |f|
					print_to_file f
				end
			else
				print_to_file $stdout
			end
		end


    def read_pl7_file(io)
      io.each_line do |l|
        mres = l.match(/^%M(W)?(\d+)(:X(\d+))?\t(\S+)\t(\S+)(\t\"?([^\t"]*))?/)
        if mres
          item = OpenStruct.new
          item.is_word = mres[1]
          item.index = mres[2].to_i
          item.bit_index = mres[4] && mres[4].to_i
          item.tagname = mres[5]
          item.comment = mres[8]
          @pl7_tags << item
        end
      end

    end
		
    def make_alarm(io)
      io.alarm_state = 'On'
      io.alarm_comment = io.comment
      io.group = @alarm_group
    end

		def print_to_file(f)
      @intouchfile = IntouchFile.new nil, @intouchoptions

      @pl7_tags.each do |item|
        data = {:item_use_tagname => 'No', :comment => item.comment }
        tag = (@prefix || '') + item.tagname
        tag = tag.upcase if @caps

        if item.bit_index
          @intouchfile.new_io_disc(tag, data) do |io|
            io.item_name = '%d:%02d' % [400001 + item.index, 16 - item.bit_index]
            make_alarm(io) if @alarm
          end
        elsif item.is_word
          @intouchfile.new_io_int(tag, data) do |io|
            io.item_name = '%d S' % (item.index + 400001)
          end
        else
          @intouchfile.new_io_disc(tag, data) do |io|
            io.item_name = (item.index + 1).to_s
            make_alarm(io) if @alarm
          end
        end
      end

      @intouchfile.write_csv f
		end


		def option_parser
			OptionParser.new do |opts|
				opts.banner = "Usage: pl7tointouch [options]"
				opts.on("-a", "--access ACCESSNAME", String, "Set access name for all tags") do |access_name|
          @intouchoptions[:access_name] = access_name
				end
				opts.on("-o", "--output FILE", String, "Output to specified file instead of", "standard output") do |output|
					@output = output
				end
				opts.on("-i", "--input FILE", String, "Input from specified file instead of", "standard input") do |input|
					@input = input
				end
				opts.on("--alarm", "Mark bit tags as alarms") do
					@alarm = true
				end
				opts.on("-g", "--alarm-group GROUP", String, "Select intouch alarm group") do |alg|
					@alarm_group = alg
          @alarm = true
				end
				opts.on("--caps", "tag name in capital letters") do
					@caps = true
				end
				opts.on("-p", "--prefix PREFIX", String, "Add PREFIX to tagname") do |prefix|
					@prefix = prefix
				end
				opts.on_tail("-h", "--help", "Show this message") do
					puts opts
					exit
				end
        # --alarm --alarmgroup 
			end	
		end
		
		def show_help
			puts option_parser
		end
	end
end


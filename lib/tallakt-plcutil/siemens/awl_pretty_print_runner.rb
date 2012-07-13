#!/usr/bin/ruby

require 'clamp'
require 'tallakt-plcutil/siemens/awl/awlfile'

module PlcUtil
	# Command line tool to read and output an awl file
	class AwlPrettyPrintRunner < Clamp::Command
		def initialize
			opt = {
        :symlist => symlist,
        :blocks => Hash[blocks.split(/[,=]/)]
      }
			
      awl_files.each do |filename|
        process_awl_file Awl::AwlFile.new(filename), opt
      end
		end
		
    def fix_name(name)
      if no_block?
        name.sub /^[^\.]*\./, ''
      else
        name
      end
    end

		def process_awl_file(f)
			@awl.each_exploded do |addr, name, comment, type_name|
				f.puts '%-11s %-40s%-10s%s' % [
          addr.to_s,
          fix_name(name), 
          type_name.to_s.upcase,
          comment
        ]
			end
		end
		
    option %w(--no-block -n), :flag, "don't use datablock as part of the tagname"
    option %w(--symlist -s), 'FILE', 'specify SYMLIST.DBF frfom Step 7 project'
    option %w(--block-name -b), 'NAME=ADDR,NAME=ADDR', 'specify DB adress directly instead of using SYMLIST.DBF' do |s|
      raise 'Invalid format of block names, example use: A=DB20,B=DB21' unless s.match(/(\w+=\w+,)*(\w+=\w+)/)
    end

    parameter "AWLFILES ...", 'awl files to read (exported inside Step 7)', :attribute_name => :awl_files
	end
end

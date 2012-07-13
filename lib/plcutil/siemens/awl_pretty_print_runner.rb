#!/usr/bin/ruby

require 'clamp'
require 'plcutil/siemens/awl/awlfile'

module PlcUtil
	# Command line tool to read and output an awl file
	class AwlPrettyPrintRunner < Clamp::Command
		def execute
			opt = {
        :symlist => symlist,
        :blocks => Hash[block_name.split(/[,=]/)]
      }
			
      file_list.each do |filename|
        process_awl_file Awl::AwlFile.new(filename, opt)
      end
		end
		
    def fix_name(name)
      if no_block?
        name.sub /^[^\.]*\./, ''
      else
        name
      end
    end

		def process_awl_file(awl)
			awl.each_exploded do |addr, name, comment, type_name|
				puts '%-11s %-40s%-10s%s' % [
          addr.to_s,
          fix_name(name), 
          type_name.to_s.upcase,
          comment
        ]
			end
		end
		
    option %w(--no-block -n), :flag, "don't use datablock as part of the tagname"
    option %w(--symlist -s), 'FILE', 'specify SYMLIST.DBF frfom Step 7 project'
    option %w(--block-name -b), 'NAME=ADDR,NAME=ADDR', 'specify DB adress directly instead of using SYMLIST.DBF', :default => '' do |s|
      raise 'Invalid format of block names, example use: A=DB20,B=DB21' unless s.match(/(\w+=\w+,)*(\w+=\w+)/)
    end

    parameter "FILE ...", 'awl files to read (exported inside Step 7)'
	end
end

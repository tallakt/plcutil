#!/usr/bin/ruby
require 'clamp'
require 'dbf'
module PlcUtil
	class AwlLsRunner < Clamp::Command
		def execute
      # search for dbf file containing internal name -> awl file
      dbf_files = Dir["#{folder || '.'}/**/S7CONTAI.DBF"]
      if dbf_files.empty?
        puts 'No S7CONTAI.DBF found in folder' 
      else
        awl_to_siemens = dbf_files.map do |s7contai|
          dbf = DBF::Table.new s7contai
          dir = File::dirname s7contai
          Hash[dbf.select {|x| x }.map {|row| [File.join(dir, row.filename), row.name]}]
        end.reduce(&:merge)

        expanded = file_list.map {|f| File::expand_path f }
        interesting = awl_to_siemens.select {|k,v| expanded.member?(File.expand_path(k)) || file_list.member?(v) || file_list.empty? }
        longest = interesting.values.sort {|a,b| a.length <=> b.length }.last
        interesting.each {|k,v| puts "%-#{longest.length}s %s" % [v, k] }
      end
		end
		
    option %W(-f --folder), 'FOLDER', 'folder containing one or more Siemens Step 7 projects'
    parameter "[FILE] ...", 'either siemens Step 7 names of source files, or AWL files to check'
	end
end

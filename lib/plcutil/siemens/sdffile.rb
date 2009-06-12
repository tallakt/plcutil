#!/usr/bin/env ruby

require 'ostruct'

module PlcUtil
	class SdfFile
    attr_reader :tags

		def initialize(filename)
      @tags = []
      case filename
      when /\-\-/
        parse $stdin
      else
        File.open filename do |f|
          parse f
        end
      end
		end


    private

    def parse(f)
      f.each_line do |l|
        tag = OpenStruct.new([:tagname, :addr, :datatype, :comment].zip(l.strip.split(/,/).map do |x| 
          x.gsub(/^"|"$/, '').strip 
        end))
        tag.addr.gsub! /\s+/, ' '
        if not tag.datatype.match(/\s/) # skip OB XX, FC XX, FB XX and so on
          begin
            tag.datatype = tag.datatype.downcase.to_sym
            @tags << tag
          rescue
            # no worries
          end
        end
      end
    end
  end  
end


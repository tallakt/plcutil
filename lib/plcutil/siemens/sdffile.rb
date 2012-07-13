#!/usr/bin/env ruby

require 'ostruct'

module PlcUtil
	class SdfFile
    attr_reader :tags

		def initialize(filename = nil)
      @tags = []
      case filename
      when '--'
        parse $stdin
      when nil
        # dont read file
      else
        File.open filename do |f|
          parse f
        end
      end
		end


    private

    def parse(f)
      f.each_line do |l|
        item = {}
        values = l.strip.split(/,/).map do |x| 
          x.gsub(/^"|"$/, '').strip 
        end
        item = Hash[[:name, :addr, :type, :comment].zip values]
        item[:addr].gsub! /\s+/, ' '
        if not item[:type].match(/\s/) # skip OB XX, FC XX, FB XX and so on
          begin
            item[:type] = item[:type].downcase.to_sym
            @tags << item
          rescue
            # no worries
          end
        end
      end
    end
  end  
end


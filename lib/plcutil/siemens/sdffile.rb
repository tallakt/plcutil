#!/usr/bin/env ruby

require 'ostruct'

module PlcUtil
	class SdfFile
    attr_reader :tags

		def initialize(filename)
			File.open filename do |f|
				parse f
			end
      tags = []
		end


    private

    def parse(f)
      f.each_line do |l|
        tag = OpenStruct.new([:tagname, :addr, :type, :comment].zip(l.strip.split(/,/).map {|x| x.strip }))
        tag.addr.gsub! /\s+/, ' '
        tag.type = tag.type.downcase.to_sym
        @tags << tag
      end
    end
  end  
end


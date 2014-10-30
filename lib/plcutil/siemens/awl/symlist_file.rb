require 'dbf'

module PlcUtil
  module Awl
		class SymlistFile
			def initialize(filename)
        @symlist = {}
        raise 'Specified symlist file not found' unless File.exists? filename
        table = DBF::Table.new filename
        table.each do |rec|
          next unless rec
          @symlist[rec.attributes['_SKZ']] = rec.attributes['_OPIEC']
        end
			end

      def [](tag)
        lookup tag
      end

      def lookup(tag)
        @symlist[tag]
      end
		end
  end
end




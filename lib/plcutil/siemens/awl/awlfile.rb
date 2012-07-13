#!/usr/bin/ruby

require 'polyglot'
require 'treetop'
require 'tallakt-plcutil/siemens/awl/basic_type'
require 'tallakt-plcutil/siemens/awl/struct_type'
require 'tallakt-plcutil/siemens/awl/array_type'
require 'tallakt-plcutil/siemens/awl/treetop_nodes'
require 'tallakt-plcutil/siemens/awl/awl.treetop'


module PlcUtil
  module Awl
    class AwlFile
      attr_reader :symlist

      def initialize(filename, options = {})
        @symlist = (options[:symlist] && SymlistFile.new(options[:symlist])) || {}

        # parse file
        parser = PlcUtil::Awl::AwlGrammar.new
        awl_nodes = parser.parse File.read(filename)
        @awl = awl_nodes && awl_nodes.visit
        if !@awl
          raise [
            "Unable to parse file: #{filename}",
            "Failure on line #{parser.failure_line} column #{parser.failure.column}",
            "Details:",
            parser.failure_reason.inspect,
          ].join("\n")
        else
          require 'awesome_print'
          ap @awl
        end
      end

      def lookup_symlist(tag)
        (options[:blocks] && options[:blocks][tag]) || (@symlist && @symlist[tag])
      end
      
      def each_exploded(options = {})
        @awl[:dbs].each do |raw|
          db = create_struct raw
          name = if options[:no_block] 
                   ''
                 else 
                   raw[:id]
                 end

          a = DbAddress.new 0, db_address(raw[:id])
          db.each_exploded(a, name).each do |addr, name, comment, type_name|
            yield addr, name, comment, type_name
          end
        end
      end
      
      def db_address(name)
        if @symlist.key? name
          @symlist[name].gsub /\s+/, ''
        end
      end
      private :db_address
      
      def get_udt(name)
        udt = @awl[:udts].find {|u| u[:name] == name }
        raise "Could not find UDT with name: #{name}" unless udt
        create_struct udt
      end
      private :get_udt

      def create_struct(raw)
        StructType.new.tap do |s|
          raw.entries.each do |e|
            base_type = case e[:data_type]
              when Hash
                # anonymous structure inline
                create_struct(e)
              when String
                # UDT
                get_udt e[:data_type]
              when Symbol
                  BasicType::create e[:data_type]
              end
            if e.key? :array
              s.add_child e[:id], ArrayType.new(basic_type, e[:array])
            else
              s.add_child e[:id], basic_type
            end
          end
        end
      end
      private :create_struct
		end
	end
end

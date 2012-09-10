#!/usr/bin/ruby

require 'polyglot'
require 'treetop'
require 'plcutil/siemens/awl/basic_type'
require 'plcutil/siemens/awl/struct_type'
require 'plcutil/siemens/awl/array_type'
require 'plcutil/siemens/awl/treetop_nodes'
require 'plcutil/siemens/awl/db_address'
require 'plcutil/siemens/awl/awl.treetop'


module PlcUtil
  module Awl
    class AwlFile
      attr_reader :symlist

      def initialize(filename, options = {})
        @symlist = options[:symlist] && SymlistFile.new(options[:symlist]) || {}
        # parse file
        parser = PlcUtil::Awl::AwlGrammarParser.new
        awl_nodes = parser.parse File.read(filename)
        @awl = awl_nodes && awl_nodes.visit
        if !@awl
          raise [
            "Unable to parse file: #{filename}",
            "Failure on line #{parser.failure_line} column #{parser.failure_column}",
            "Details:",
            parser.failure_reason.inspect,
          ].join("\n")
        end
      end

      def lookup_symlist(tag)
        (options[:blocks] && options[:blocks][tag]) || (@symlist && @symlist[tag])
      end
      
      def each_exploded(options = {}, &block)
        @awl[:dbs].each do |raw|
          db = create_struct raw
          name = if options[:no_block] 
                   ''
                 else 
                   raw[:id]
                 end

          a = DbAddress.new 0, db_address(raw[:name])
          db.each_exploded(a, name) do |addr, name, comment, type_name|
            yield addr, name, comment, type_name
          end
        end
      end
      
      def db_address(name)
        n = @symlist[name]
        n && n.gsub(/\s/, '')
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
          raw[:entries].each do |e|
            base_type = case e[:data_type]
              when Hash
                # anonymous structure inline
                create_struct(e[:data_type])
              when String
                # UDT
                get_udt e[:data_type]
              when Symbol
                  BasicType::create e[:data_type]
              end
            if e.key? :array
              s.add e[:id], ArrayType.new(base_type, e[:array]), e[:comment]
            else
              s.add e[:id], base_type, e[:comment]
            end
          end
        end
      end
      private :create_struct
		end
	end
end

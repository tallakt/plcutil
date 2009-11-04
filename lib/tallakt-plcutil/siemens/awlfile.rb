#!/usr/bin/ruby

require 'rubygems'

module PlcUtil

	# Reads a Siemens Step 7 AWL file and creates single tags with addresses and comment
	class AwlFile
    attr_reader :symlist

		def initialize(filename, options = {})
			@types = {}
			init_basic_types
			@datablocks = []
			@symlist = {}
			
			if options[:symlist]
        require 'dbf' or raise 'Please install gem dbf to read symlist file'

				raise 'Specified symlist file not found' unless File.exists? options[:symlist]
				table = DBF::Table.new(options[:symlist])
				table.records.each do |rec|
					@symlist[rec.attributes['_skz']] = rec.attributes['_opiec'] # or _ophist or _datatyp
				end
			end

			@symlist.merge!(options[:blocks] || {}) # User may override blocks
			
			File.open filename do |f|
				parse f
			end
		end
		
		def each_tag(options = {})
			@datablocks.each do |var|
        name = var.name
        if options[:no_block]
          name = nil
        end
				var.type.explode(Address.new(0, data_block_address(var.name)), name, options).each do |item|
          ii = item.clone
          ii[:type] = item[:type].downcase.to_sym
					yield ii
				end
			end
		end
		
		private
		
		def data_block_address(name)
			if @symlist.key? name
				@symlist[name].gsub /\s+/, ''
			else
				nil
			end
		end
		
		def init_basic_types
      types = {
        'BOOL' => 1,
        'BYTE' => 8,
        'CHAR' => 8,
        'DATE' => 2 * 8, 
        'DINT' => 4 * 8,
        'DWORD' => 4 * 8,
        'INT' => 2 * 8,
        'REAL' => 4 * 8,
        'S5TIME' => 2 * 8,
        'TIME' => 4 * 8,
        'TIME_OF_DAY' => 4 * 8,
        'WORD' => 2 * 8,
        'DATE_AND_TIME' => 4 * 8, # ??? only used in VAR_TEMP
        'TIMER' => 1, # Only in FC calls
        'CONT_C' => 125 * 8, 
      }
      types.each {|name, size| add_type BasicType.new(name, size) }
		end
		
		def add_type(type)
				@types[type.name] = type
		end

		def lookup_type(type)
			raise "Could not find type '#{type}'" unless @types.key? type
			@types[type]
		end
		
		def parse(file)
			stack = []
			in_array_decl = false
      in_datablock_decl = false
			tagname = start = stop = type = comment = nil
      db_to_fb = {}
			file.each_line do |l|
        l.chomp!
				if in_array_decl
					if l.match '^\s+\"?([A-Za-z0-9_]+)"?\s?;'
						type = $1
						stack.last.add Variable.new(tagname, ArrayType.new(@types[type], start..stop), comment)
					end
					in_array_decl = false
				else
					in_array_decl = false
					case l
            # TODO should also cater for 'DB  90' type addresses
          when /^TYPE "(.+?)"/ 
            stack = [StructType.new $1, :datatype]
            add_type stack.last
          when /^FUNCTION_BLOCK "(.+?)"/
            stack = [StructType.new $1, :functionblock]
            add_type stack.last
          when /^DATA_BLOCK ("(.+?)"|DB\s+(\d+))/
            in_datablock_decl = true
            name = $2 || ('DB' + $3)
            stack = [StructType.new name, :datablock]
            @datablocks << Variable.new(name, stack.last)
          when /^VAR_TEMP/
            s = StructType.new 'VAR_TEMP', :anonymous
            stack = [s]
          when /^\s*(\S+) : STRUCT /
            in_datablock_decl = false
            s = StructType.new 'STRUCT', :anonymous
            stack.last.add Variable.new $1, s
            stack << stack.last.children.last.type
          when /^BEGIN$/
            in_datablock_decl = false
          when /^\s+BEGIN/
            stack.pop
          # New variable in struct or data block
          when /^\s+([A-Za-z0-9_ ]+) : "?([A-Za-z0-9_ ]+?)"?\s*(:=\s*[^;]+)?;(\s*\/\/(.*))?/
            if stack.any?
              tagname, type_name, comment = $1, $2, ($5 || '')
              stack.last.add Variable.new(tagname, lookup_type(type_name), comment)
            end
          when /^\s+([A-Za-z0-9_]+) : ARRAY\s*\[(\d+)\D+(\d+) \] OF "?([A-Za-z0-9_]+)"?\s?;(\s*\/\/(.*))?/
            tagname, start, stop, type, comment = $1, $2, $3, $4, $6
            stack.last.add Variable.new(tagname, ArrayType.new(lookup_type(type), start..stop), comment)
          when /^\s+([A-Za-z0-9_]+) : ARRAY\s*\[(\d+)\D+(\d+) \] OF(\s?\/\/(.*))?$/
            tagname, start, stop, comment = $1, $2, $3, $4
            in_array_decl = true
          when /^"(.*?)"$/
            # datablock definition is stored in FB definition
            # remember which FB to use but assign the FB
            # only after all blocks have been loaded
            db_to_fb[stack.first.name] = $1 if in_datablock_decl
					end
				end
			end

      # Update FB to DB use
      @datablocks.each do |db|
        if db_to_fb.key? db.name
          fb = lookup_type db_to_fb[db.name]
          fb.children.each {|child| db.type.add child } if fb.respond_to? :children
        end
      end
		end
		
		def defined_type(type)
			@types.key?(type.name)
		end
		
		
		class BasicType
			attr_accessor :bit_size, :name
			
			def initialize(name, bit_size)
				@bit_size, @name = bit_size, name
			end
			
			def explode(start_addr, name, comment, struct_comment, options = {})
        actual_start = start_addr.next_start bit_size
        [{:addr => actual_start, :name => name, 
          :struct_comment => struct_comment, :comment => comment, :type => @name}]
			end
			
			def end_address(start_address)
				start_address.next_start(bit_size).skip! bit_size
			end
		end


		
		class StructType
			attr_accessor :name, :children, :type
			
			def initialize(name = 'STRUCT', type = :anonymous)
				@name = name
				@children = []
        @type = type
			end
			
			def add(child)
				raise 'Added nil child' unless child
				raise 'Added nil child type' unless child.type
				@children << child
			end
				
			def end_address(start_address) 
				addr = start_address.next_start
				@children.each do |child|
					addr = child.type.end_address addr
				end
        addr.next_start!
			end
			
			def explode(start_addr, name, comment = nil, struct_comment = nil, options = {})
				addr = start_addr.next_start
				exploded = []
				@children.each do |child|

					exploded += child.type.explode(addr, [name, child.name].compact.join('.'), child.comment, 
                                         type == :datablock ? child.comment : struct_comment, options)
					addr = child.type.end_address addr
				end
				exploded
			end
		end
		
		class ArrayType
			attr_accessor :range, :type
			
			def initialize(type, range)
				raise 'Added nil array type' unless type
				raise 'Added nil array range' unless range
				@range, @type = range, type
			end
			
			def name
				'ARRAY'
			end

			def end_address(start_address) 
				addr = start_address.next_start
				range.each do
					addr = type.end_address addr
				end
				addr
			end

			def explode(start_addr, name, comment, struct_comment, options = {})
				exploded = []
				addr = start_addr.next_start
				range.to_a.each_with_index do |v, i|
					exploded += type.explode(addr, name + '[' + v.to_s + ']', comment, struct_comment, options = {})
					addr = type.end_address(addr)
				end
				exploded
			end
		end
		
		class Variable
			attr_accessor :name, :type, :comment

			def initialize(name, type, comment = nil)
				@name, @type, @comment= name, type, comment
			end
		end
		
		class Address
			attr_accessor :bit_addr, :data_block_addr
			
			def initialize(bit_addr, data_block_addr = nil)
				@bit_addr, @data_block_addr = bit_addr, data_block_addr
			end
			
			def to_s
				(data_block_addr || 'DB???') + ',' + byte.to_s + '.' + bit.to_s
			end

      def bit
        @bit_addr % 8
      end

      def byte
        @bit_addr / 8
      end

      def next_start!(bit_size = 2 * 8)
        bs = [bit_size, 2 * 8].min  # bools use bits, chars/bytes one byte others two byte rounding of start address
        rest = @bit_addr % bs
        @bit_addr += (bs - rest) if rest > 0
        self
      end

      def next_start(bit_size = 2 * 8)
        self.clone.next_start! bit_size
      end

      def skip!(bit_count)
        @bit_addr += bit_count
        self
      end
		end
	end
end
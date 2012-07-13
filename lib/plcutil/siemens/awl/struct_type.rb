module PlcUtil
  module Awl
		class StructType
			def initialize
				@children = []
			end
			
			def add(name, type, comment)
				@children << {:name => name, :type => type, :comment => comment}
			end
				
      def skip_padding(addr)
        addr.next_word
      end

      def end_address(start_addr)
        @children.inject(start_addr) {|addr, ch| ch[:type].end_address addr }
      end

			def each_exploded(start_addr, name_prefix, &block)
				addr = skip_padding start_addr
        @children.each do |ch|
          full_name = if !name_prefix || name_prefix.empty?
                        ch[:name]
                      else
                        "#{name_prefix}.#{ch[:name]}"
                      end
          case ch[:type]
          when StructType
            addr = ch[:type].each_exploded(addr, full_name) do |a, n, c, t|
              yield a, n, c, t
            end
          when ArrayType
            ct = ch[:type]
            addr = ct.skip_padding addr
            ct.range.each do |n|
              yield addr, "#{full_name}[#{n}]", ch[:comment], ct.element_type.type_name
              addr = ct.element_type.end_address addr
            end
          when BasicType
            ct = ch[:type]
            addr = ct.skip_padding addr
            yield addr, full_name, ch[:comment], ct.type_name
            addr = ct.end_address addr
          end
        end
        addr
			end
		end
  end
end


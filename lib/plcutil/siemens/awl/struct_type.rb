module PlcUtil
  module Awl
		class StructType
			def initialize
				@children = []
			end
			
			def add(name, type, comment)
				raise 'Added nil child' unless child
				raise 'Added nil child type' unless type
				@children << {:name => name, :type => type, :comment => comment}
			end
				
      def skip_padding(addr)
        addr.next_word
      end

      def end_address(start_addr)
        @children.inject(start_addr) {|addr, ch| ch[:type].end_address addr }
      end

			def each_exploded(start_addr, name_prefix)
				addr = start_addr.skip_padding
        @children.each do |ch|
          full_name = if name_prefix.empty?
                        child
                      else
                        "#{name_prefix}.#{child}"
                      end
          case ch
          when StructType
            addr = ch.explode addr, full_name
          when ArrayType
            ct = ch[:type]
            addr = ct.skip_padding addr
            ct.range.each do |n|
              yield addr, "#{full_name}[#{n}]", ch[:comment], ct.type
              addr = ct.element_type.end_address start_addr
            end
          when BasicType
            ct = ch[:type]
            addr = ct.skip_padding addr
            yield addr, full_name, ch[:comment], ct.type
            addr = ct.end_address start_addr
          end
        end
        addr
			end
		end
  end
end


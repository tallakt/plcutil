module PlcUtil
  module Awl
		class ArrayType
			attr_accessor :range, :element_type
			
			def initialize(element_type, range)
				@range, @element_type = range, element_type
			end
			
      def skip_padding(addr)
        addr.next_word
      end

      def end_address(start_addr)
        start_addr.skip type.bit_size * range.count
      end
		end
  end
end



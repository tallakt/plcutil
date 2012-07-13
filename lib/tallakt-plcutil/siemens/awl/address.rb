module PlcUtil
  module Awl
		class DbAddress
			attr_accessor :data_block_addr
			
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

      def next_word
        # simatic packing rules
        # 1. 16 bit values aligned at modulo 2 address 0.0, 2.0, 4.0, 8.0, ...
        # 2. 8 bit values aligned at each address, 0.0, 1.0, 2.0, ...
        # 3. Structs are aligned modulo 2
        # 4. Bools are aligned like 8 bit values, consecutive bools occupy a single byte
        DbAddress.new (@bit_addr / 16 + 1) * 16, data_block_addr
      end

      def next_byte
        DbAddress.new (@bit_addr / 8 + 1) * 8, data_block_addr
      end

      def next_bool
        DbAddress.new @bit_addr + 1, data_block_addr
      end

      def skip(bit_count)
        DbAddress.new @bit_addr + bit_count, data_block_addr
      end
		end
  end
end

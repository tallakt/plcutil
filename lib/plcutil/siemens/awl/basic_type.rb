module PlcUtil
  module Awl
    class BasicType
      TYPES = {
        :bool => 1,
        :byte => 8,
        :char => 8,
        :date => 16,
        :dint => 32,
        :dword => 32,
        :int => 16,
        :real => 32,
        :s5time => 16,
        :time => 32,
        :time_of_day => 32,
        :word => 16,
        :date_and_time => 32, # only in VAR_TEMP
        :timer => 1,          # only in FC calls
        :cont_c => 125 * 8
      }

      attr_accessor :bit_size, :type_name
      
      def initialize(bit_size, type_name)
        @bit_size, @type_name = bit_size, type_name
      end
      
      def skip_padding(addr)
        case bit_size
        when 1
          addr
        when 8
          addr.next_byte
        else
          addr.next_word
        end
      end

      def end_address(start_addr)
        start_addr.skip bit_size
      end

      def BasicType.create(type_key)
        b = TYPES[type_key]
        raise "Could not find type: #{type_key.to_s}" unless b
        BasicType.new b, type_key
      end
    end

  end
end


#!/usr/bin/ruby

require 'yaml'

module PlcUtil
	# Reads a Siemens Step 7 AWL file and creates single tags with addresses and comment
	class IntouchFile
		ApostropheReqiredColumns =
			%w(
				SymbolicName Comment OnMsg Group AccessName 
        HiAlarmInhibitor MajDevAlarmInhibitor 
        DSCAlarmInhibitor InitialMessage 
				HiHiAlarmInhibitor tag Application MinDevAlarmInhibitor 
        Topic AlarmComment EngUnits LoAlarmInhibitor 
				OffMsg LoLoAlarmInhibitor RocAlarmInhibitor ItemName
			)

		def initialize(filename = nil, options = {})

      # load standard sections
			@sections = YAML.load_file File.join(File.dirname(__FILE__), "standard_sections.yaml")
      each_section {|sec| define_data_class @sections[sec][:colnames]}

      @options = options

			if filename
				File.open filename, 'r' do |f|
					read_csv f
				end
			end
    end

    def each_section
			@sections.each_key {|k| yield k}
		end
	

		def find_tag(tag, section = nil)
      if section
        @sections[section][:rows].find {|row| row.tag == tag}
      else
        result = []
        @sections.each do |name, sec|
          result << sec[:rows].find {|row| row.tag == tag }
        end
        result.find {|x| x }
      end
		end


    def each_tag(section) 
      @sections[section][:rows].each {|r| yield r }
    end
		
    def clear
      each_section do |s|
        @sections[s][:rows] = []
      end
    end
		
    def read_csv_file(filename)
      File.open filename do |f|
        read_csv f
      end
    end

    def write_csv_file(filename)
      File.open filename, 'w' do |f|
        write_csv f
      end
    end


		def read_csv(io)
			colnames = nil
			current = nil
			io.each do |l|
				case l.chomp!
					when /^:mode=/
						# ignore line
					when /^:/
						# new section
						colnames = l.split /;/
						name = colnames.first
						unless @sections.key? name
							@sections[name] = {}
							@sections[name][:colnames] = colnames
							@sections[name][:rows] = []
							@sections[name][:name] = name
              define_data_class colnames
						end
						current = @sections[name]
					else
						# new tag
            cols = l.gsub(/"/, '').split /;/
						new_data_instance(current[:name][1..-1], cols[0], cols[1..-1], colnames)
				end
			end
		end
		
		def write_csv(io, mode = :update)
			raise 'Please use mode :ask/:update/:replace' unless [:ask, :replace, :update].include? mode
			io.puts ':mode=' + mode.to_s
			@sections.each_value do |section|
        next if section[:rows].empty?
				io.puts section[:colnames].join ';'
				section[:rows].each do |row|
          io.puts row.to_csv
				end
			end
		end
	
    private


    def apostrophe_req?(colname)
			# Lookup table to check wether a certain column must write its values inside apostrophes
			@@lookup_apostrophe_fields ||= ApostropheReqiredColumns.inject({}) {|h, v| h[v] = true; h}
      @@lookup_apostrophe_fields[colname] || colname.match(/^:/)
    end

    def to_csv_line(colnames)
      '[%s].join ";"' % colnames.map do |c|
        cc = c.match(/^:/) ? 'tag' : dasherize(c)
        if apostrophe_req? c
          # When nil, dont display the "" chars, since this will overwrite with an empty string
          # The check is performed at runtime in the generated class
          # The result should look like: (tag ? '"%s"' : '%s') % tag
          %Q!\n  (#{cc} ? '"%s"' : '%s') % #{cc}!
        else
          %Q!\n  #{cc}.to_s!
        end
      end.join(',')
    end

    def define_data_class(colnames)
      # define new class for the data type
      klass = colnames[0][1..-1]
      #return if defined? klass
      attrs = colnames[1..-1].map {|x| ':' + dasherize(x) }.join(', ')
      attr_list = colnames[1..-1].map {|x| dasherize(x)}.join(', ')
      values_format = colnames.map {|c| apostrophe_req?(c) ? '"%s"' : '%s'}.join(';')

      PlcUtil.module_eval <<-END
        class #{klass}
          attr_accessor #{attrs}
          attr_accessor :tag

          def initialize(tag, values={})
            @tag = tag
            values.each do |key, value|
              mn = key.to_s + '='
              method(mn).call(value) if respond_to?(mn)
            end
          end

          def to_csv
            #{to_csv_line colnames}
          end

          def intouch_fields
            [#{attrs}]
          end

          def to_h
            result = {:tag => tag }
            intouch_fields.each do |field|
              result[field] = method(field).call
            end
            result
          end

          def alarm?
            respond_to?(:alarm_state) && alarm_state && alarm_state.match(/On|Off/)
          end
        end
      END

      # define method to create new instances
      IntouchFile.class_eval <<-END
        public
        
        def new_#{dasherize klass}(tag, values = {})
          result = #{klass}.new tag, values
          @sections['#{colnames[0]}'][:rows] << result
          if result.respond_to? :access_name 
            result.access_name = @options[:access_name] if @options[:access_name]
          end
          yield result if block_given?
          result
        end
      END
    end

    def new_data_instance(klass, tag, values, colnames)
      attributes = colnames[1..-1].map {|cn| dasherize(cn)}
      method('new_' + dasherize(klass)).call(tag, Hash[attributes.zip(values)])
    end

    def dasherize(s)
      res = s.gsub(/[A-Z]{3,}/){|x| x[0..-2].capitalize + x[-1..-1]}
      res.gsub!(/[A-Z]/, '_\0')
      res.gsub! /^_/ , ''
      res.downcase!
    end
  end
end

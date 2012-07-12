require 'treetop'

module Awl
  module StructHelpers
    def struct_visit_helper(struct_node)
      struct_node.decl.elements.map do |el| 
        { :id => el.identifier.text_value }.tap do |result|
          el.d.visit result
        end
      end
    end
  end

	module TopLevelNode
		def visit
			{
				:dbs => [],
				:udts => [],
				:obs => []
			}.tap do |result|
				elements.each {|e| e.visit result }
			end
		end
	end

	module DbNode 
    include StructHelpers
		def visit(root)
			root[:dbs] << {}.tap do |db|
				name.hash_entry db
				db[:entries] = struct_visit_helper root_struct_decl.struct_data_type
			end
		end
	end

	module UdtNode 
    include StructHelpers
		def visit(root)
			root[:udts] << {}.tap do |udt|
				name.hash_entry udt
				udt[:entries] = struct_visit_helper root_struct_decl.struct_data_type
			end
		end
	end

	module ObNode
		def visit(root)
			root[:obs] << {}.tap do |ob|
				ob[:title] = title.optional_title.title_quoted.v.text_value
				name.hash_entry ob
			end
		end
	end


	module ArrayDeclarationNode
		def visit(declaration)
      declaration[:array] = (ar_begin.text_value.to_i)..(ar_end.text_value.to_i)
      declaration[:comment] = array_comment.line_comment.comment_body.text_value unless array_comment.terminal?
      non_array_data_type.visit declaration
		end
	end

	module NonArrayDeclarationNode
		def visit(declaration)
      declaration[:comment] = comment.comment_body.text_value unless comment.terminal?
      non_array_data_type.visit declaration
		end
	end

	module BasicDataTypeNode
		def visit(declaration)
      declaration[:data_type] = text_value.downcase.to_sym
		end
	end

	module StructDataTypeNode
    include StructHelpers
		def visit(declaration)
        declaration[:data_type] = {}.tap do |struct|
          struct[:entries] = struct_visit_helper self
        end
		end
	end

	module UdtDataTypeNode
		def visit(declaration)
      puts inspect
      declaration[:data_type] = v.text_value
		end
	end




	module QuotedNameNode
		def hash_entry(h)
			h[:name] = v.text_value
		end
	end

	module DbNameNode
		def hash_entry(h)
			h[:db_number] = number.to_s.to_i
		end
	end
end

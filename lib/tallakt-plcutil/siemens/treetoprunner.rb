require 'treetop'

#p AwlParser.class


#require File.expand_path('../awl', __FILE__)
Treetop.load File.expand_path('../awl.treetop', __FILE__)
parser = AwlParser.new
awl = parser.parse File.read(File.expand_path('../../../../test/input_files/step7_v5.4/00000001.AWL', __FILE__))
#awl = parser.parse ''


def printable_string(s)
  s.gsub(/\t/, '\t').gsub(/\r/, '\r').gsub(/\n/, '\n')
end

if !awl
  #puts parser.inspect
  puts 'Failure reason:'
  puts '----'
  p parser.failure_reason
  puts '----'
  #puts printable_string(parser.failure_reason)
  puts "failure_line: #{parser.failure_line}"
  puts "failure_column: #{parser.failure_column}"
else
  puts awl.inspect
end

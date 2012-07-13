require 'awesome_print'
require 'polyglot'
require 'treetop'
require File.expand_path('../treetop_nodes', __FILE__)
require File.expand_path('../awl.treetop', __FILE__)

parser = PlcUtil::Awl::AwlGrammarParser.new
awl = parser.parse File.read(File.expand_path('../../../../../test/input_files/step7_v5.4/00000001.AWL', __FILE__))


def printable_string(s)
  s.gsub(/\t/, '\t').gsub(/\r/, '\r').gsub(/\n/, '\n')
end

if !awl
  puts 'Failure reason:'
  puts '----'
  p parser.failure_reason
  puts '----'
  puts "failure_line: #{parser.failure_line}"
  puts "failure_column: #{parser.failure_column}"
else
  awesome_print awl.visit
end

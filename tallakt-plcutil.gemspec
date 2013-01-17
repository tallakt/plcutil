# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'plcutil'

Gem::Specification.new do |s|
  s.name = %q{tallakt-plcutil}
  s.version = PlcUtil::VERSION
  s.authors = ["Tallak Tveide"]
  s.date = %q{2010-10-12}
  s.description = %q{Ruby library for using Siemens, Schneider and Intouch files}
  s.email = %q{tallak@tveide.net}
  #s.executables = ["awlpp", "intouchpp", "pl7tointouch", "s7tointouch"]
  s.executables = %w(awlpp intouchpp pl7tointouch awlls symlist)
  s.extra_rdoc_files = [ "LICENSE", "README.rdoc" ]
  s.files = Dir['{lib,bin,test}/**/*'] + ["History.txt", "LICENSE", "README.rdoc"]
  s.homepage = %q{http://github.com/tallakt/plcutil}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.summary = %q{Ruby PLC file library}
  s.test_files = Dir['test/**/*']

  s.add_dependency 'dbf', ["~> 2.0"]
  s.add_dependency 'polyglot', ["~> 0.3"]
  s.add_dependency 'treetop', ["~> 1.4"]
  s.add_dependency 'clamp', ["~> 0.4"]
end


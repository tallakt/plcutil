# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'tallakt-plcutil'

Gem::Specification.new do |s|
  s.name = %q{tallakt-plcutil}
  s.version = PlcUtil::VERSION
  s.authors = ["Tallak Tveide"]
  s.date = %q{2010-10-12}
  s.description = %q{Ruby library for using Siemens, Schneider and Intouch files}
  s.email = %q{tallak@tveide.net}
  s.executables = ["awlpp", "intouchpp", "pl7tointouch", "s7tointouch"]
  s.extra_rdoc_files = [ "LICENSE", "README.rdoc" ]
  s.files = Dir['{lib,bin,test}/**/*'] + ["History.txt", "LICENSE", "README.rdoc", "Rakefile"]
  s.homepage = %q{http://github.com/tallakt/plcutil}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.summary = %q{Ruby PLC file library}
  s.test_files = Dir['test/**/*']

  s.add_dependency 'dbf', [">= 1.6.6"]
end


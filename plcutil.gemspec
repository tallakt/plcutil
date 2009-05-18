# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{plcutil}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tallak Tveide"]
  s.date = %q{2009-01-29}
  s.description = %q{A set of command line utilities and helper classes to convert between IO list files of different PLC types into different HMI types.  Currently Siemens and Wonderware are supported, Schneider and Wonderware IAS support planned in the near future.  This is still a quite rough version - pre alpha!!}
  s.email = ["tallak@tveide.net"]
  s.executables = ["awlpp", "s7tointouch"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.files = ["History.txt", "LICENSE", "Manifest.txt", "README.rdoc", "Rakefile", "TODO", "bin/awlpp", "bin/s7tointouch", "lib/plcutil/siemens/awlfile.rb", "lib/plcutil/siemens/awlprettyprintrunner.rb", "lib/plcutil/siemens/step7tointouchrunner.rb", "lib/plcutil/wonderware/intouchfile.rb", "lib/plcutil/wonderware/intouchreader.rb", "lib/plcutil/wonderware/standard_sections.yaml", "lib/plcutil.rb", "script/console", "script/console.cmd", "script/destroy", "script/destroy.cmd", "script/generate", "script/generate.cmd"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/tallakt/plcutil}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{plcutil}
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{A set of command line utilities and helper classes to convert between IO list files of different PLC types into different HMI types}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<newgem>, [">= 1.2.3"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end

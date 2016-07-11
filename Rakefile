require 'bundler/gem_tasks'

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'srfax/version'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.test_files = Dir.glob("test/**/*_test.rb")
  test.verbose = true
end

task :build do
  system "gem build srfax.gemspec"
end

task :release => :build do
  system "gem push srfax-#{SrFax::VERSION}.gem"
  system "rm srfax-#{SrFax::VERSION}.gem"
end

task :default => :test

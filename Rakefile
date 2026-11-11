require 'bundler/gem_tasks'
require 'minitest/test_task'

Minitest::TestTask.create

begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new

  task default: %i[test rubocop]
rescue LoadError
  task default: :test
end

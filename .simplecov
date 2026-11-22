SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter
])
SimpleCov.configure do
  coverage_dir "coverage"

  skip "db"
  skip "config"
  skip "bin"
  skip "spec"
  skip "lib/tasks"
end

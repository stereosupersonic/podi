SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter
])
SimpleCov.configure do
  # CI writes the report below tmp/ of its test container and copies it out from there.
  coverage_dir ENV.fetch("COVERAGE_DIR", "coverage")

  skip "db"
  skip "config"
  skip "bin"
  skip "spec"
  skip "lib/tasks"
end

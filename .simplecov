SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter
])
SimpleCov.start "rails" do
  coverage_dir "coverage"

  add_filter "db"
  add_filter "config"
  add_filter "bin"
  add_filter "spec"
  add_filter "lib/tasks"
end

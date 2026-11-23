require "rails_helper"
require "open3"

RSpec.describe "bin/coverage-check" do
  let(:project) { Pathname(Dir.mktmpdir) }

  after { FileUtils.remove_entry(project) }

  def write_source(path, text)
    project.join(path).dirname.mkpath
    project.join(path).write(text)
  end

  # The line counts SimpleCov stores, one per line of the file; nil for a line that is no code.
  def write_coverage(counts_by_path)
    files = counts_by_path.to_h { |path, counts| [ "/rails/#{path}", { "lines" => counts } ] }
    project.join("coverage").mkpath
    project.join("coverage/.resultset.json").write({ "RSpec" => { "coverage" => files, "timestamp" => 0 } }.to_json)
  end

  # A diff of git diff --unified=0 that adds count lines from line first on.
  def diff_adding(path, first, count)
    "diff --git a/#{path} b/#{path}\n--- a/#{path}\n+++ b/#{path}\n@@ -0,0 +#{first},#{count} @@\n" +
      ("+line\n" * count)
  end

  def check(diff, *arguments)
    Open3.capture2e(Rails.root.join("bin/coverage-check").to_s, *arguments, stdin_data: diff, chdir: project.to_s)
  end

  it "passes when every changed line ran" do
    write_source("app/models/painting.rb", "class Painting\n  def title = \"Mühle\"\nend\n")
    write_coverage("app/models/painting.rb" => [ 1, 3, nil ])

    _output, status = check(diff_adding("app/models/painting.rb", 1, 3))

    expect(status).to be_success
  end

  it "fails when a changed line never ran", :aggregate_failures do
    write_source("app/models/painting.rb", "class Painting\n  def title\n    \"Mühle\"\n  end\nend\n")
    write_coverage("app/models/painting.rb" => [ 1, 1, 0, nil, nil ])

    output, status = check(diff_adding("app/models/painting.rb", 2, 2))

    expect(status.exitstatus).to eq(1)
    expect(output).to include(%(app/models/painting.rb:3  "Mühle"))
  end

  it "does not name a line that ran" do
    write_source("app/models/painting.rb", "class Painting\n  def title\n    \"Mühle\"\n  end\nend\n")
    write_coverage("app/models/painting.rb" => [ 1, 1, 0, nil, nil ])

    output, _status = check(diff_adding("app/models/painting.rb", 2, 2))

    expect(output).not_to include("app/models/painting.rb:2")
  end

  it "passes when a line that never ran was not changed" do
    write_source("app/models/painting.rb", "class Painting\n  def title\n    \"Mühle\"\n  end\nend\n")
    write_coverage("app/models/painting.rb" => [ 1, 1, 0, nil, nil ])

    _output, status = check(diff_adding("app/models/painting.rb", 1, 2))

    expect(status).to be_success
  end

  it "reads a hunk of a single line, which git writes without a count" do
    write_source("app/models/painting.rb", "class Painting\n  def title\n    \"Mühle\"\n  end\nend\n")
    write_coverage("app/models/painting.rb" => [ 1, 1, 0, nil, nil ])
    diff = "--- a/app/models/painting.rb\n+++ b/app/models/painting.rb\n@@ -3 +3 @@\n-    \"Mill\"\n+    \"Mühle\"\n"

    _output, status = check(diff)

    expect(status.exitstatus).to eq(1)
  end

  it "passes when lines were only removed" do
    write_source("app/models/painting.rb", "class Painting\n  def title\n    \"Mühle\"\n  end\nend\n")
    write_coverage("app/models/painting.rb" => [ 1, 1, 0, nil, nil ])
    diff = "--- a/app/models/painting.rb\n+++ b/app/models/painting.rb\n@@ -4,2 +3,0 @@\n-  # old\n-  # older\n"

    _output, status = check(diff)

    expect(status).to be_success
  end

  it "leaves out the lines between two :nocov: markers" do
    write_source("app/models/painting.rb",
                 "class Painting\n  # :nocov:\n  def title\n    \"Mühle\"\n  end\n  # :nocov:\nend\n")
    write_coverage("app/models/painting.rb" => [ 1, nil, 0, 0, nil, nil, nil ])

    _output, status = check(diff_adding("app/models/painting.rb", 3, 3))

    expect(status).to be_success
  end

  it "fails for a changed file of Ruby the specs never loaded", :aggregate_failures do
    write_source("app/services/forgotten.rb", "class Forgotten\nend\n")
    write_coverage("app/models/painting.rb" => [ 1 ])

    output, status = check(diff_adding("app/services/forgotten.rb", 1, 2))

    expect(status.exitstatus).to eq(1)
    expect(output).to include("app/services/forgotten.rb")
  end

  it "passes for a changed file that is not Ruby" do
    write_source("app/views/paintings/show.html.haml", "%h1 Mühle\n")
    write_coverage("app/models/painting.rb" => [ 1 ])

    _output, status = check(diff_adding("app/views/paintings/show.html.haml", 1, 1))

    expect(status).to be_success
  end

  it "passes for a changed file of Ruby outside app, lib and mcp/lib" do
    write_source("db/seeds.rb", "puts 1\n")
    write_coverage("app/models/painting.rb" => [ 1 ])

    _output, status = check(diff_adding("db/seeds.rb", 1, 1))

    expect(status).to be_success
  end

  it "passes for a deleted file" do
    write_coverage("app/models/painting.rb" => [ 1 ])
    diff = "--- a/app/models/gone.rb\n+++ /dev/null\n@@ -1,2 +0,0 @@\n-class Gone\n-end\n"

    _output, status = check(diff)

    expect(status).to be_success
  end

  it "passes when no file changed" do
    write_coverage("app/models/painting.rb" => [ 1 ])

    _output, status = check("")

    expect(status).to be_success
  end

  it "takes a line as run when one of several runs of the suite ran it" do
    write_source("app/models/painting.rb", "class Painting\n  def title = \"Mühle\"\nend\n")
    runs = { "RSpec" => { "lines" => [ 1, 0, nil ] }, "Parallel" => { "lines" => [ 1, 2, nil ] } }
    project.join("coverage").mkpath
    project.join("coverage/.resultset.json").write(
      runs.transform_values { |file| { "coverage" => { "/rails/app/models/painting.rb" => file } } }.to_json
    )

    _output, status = check(diff_adding("app/models/painting.rb", 2, 1))

    expect(status).to be_success
  end

  it "reads the coverage from the file it is given" do
    write_source("app/models/painting.rb", "class Painting\nend\n")
    project.join("elsewhere.json").write(
      { "RSpec" => { "coverage" => { "/rails/app/models/painting.rb" => { "lines" => [ 1, nil ] } } } }.to_json
    )

    _output, status = check(diff_adding("app/models/painting.rb", 1, 1), "elsewhere.json")

    expect(status).to be_success
  end

  it "refuses to run without coverage", :aggregate_failures do
    output, status = check(diff_adding("app/models/painting.rb", 1, 1))

    expect(status.exitstatus).to eq(2)
    expect(output).to include("coverage/.resultset.json")
  end
end

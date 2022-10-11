require "nokogiri"
require "compare-xml"

RSpec::Matchers.define :match_xml do |expected_html, **options|
  match do |actual_html|
    expected_doc = Nokogiri::XML(expected_html)
    actual_doc = Nokogiri::XML(actual_html)

    # Options documented here: https://github.com/vkononov/compare-xml
    default_options = {
      collapse_whitespace: true,
      ignore_attr_order: true,
      ignore_comments: true
    }

    options = default_options.merge(options).merge(verbose: true)

    diff = CompareXML.equivalent?(expected_doc, actual_doc, **options)

    diff.blank?
  end
end

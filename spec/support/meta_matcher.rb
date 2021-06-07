RSpec::Matchers.define :have_meta do |name, expected|
  match do |_actual|
    if name.include?("og:")
      has_css?("meta[property='#{name}'][content='#{expected}']", visible: false)
    else
      has_css?("meta[name='#{name}'][content='#{expected}']", visible: false)
    end
  end

  failure_message do |_actual|
    actual = if name.include?("og:")
      first("meta[property='#{name}']", visible: false)
    else
      first("meta[name='#{name}']", visible: false)
    end

    if actual
      "expected that meta #{name} would have content='#{expected}' but was '#{actual[:content]}'"
    else
      "expected that meta #{name} would exist with content='#{expected}'"
    end
  end
end

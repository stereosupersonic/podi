# Episode texts end up in the RSS feed, where podcast apps cannot resolve links without a domain.
class AbsoluteLinksValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, markdown)
    links = relative_links(markdown)
    record.errors.add(attribute, "contains links without https://: #{links.join(', ')}") if links.any?
  end

  private

  def relative_links(markdown)
    html = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true).render(markdown.to_s)
    hrefs = Nokogiri::HTML5.fragment(html).css("a[href]").map { |link| link["href"] }
    hrefs.reject { |href| href.start_with?("mailto:") || UrlValidator.valid_url?(href) }
  end
end

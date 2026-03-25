xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc root_url
    xml.changefreq "daily"
    xml.priority "1.0"
  end

  xml.url do
    xml.loc episodes_url
    xml.changefreq "daily"
    xml.priority "0.8"
  end

  xml.url do
    xml.loc about_url
    xml.changefreq "monthly"
    xml.priority "0.5"
  end

  xml.url do
    xml.loc imprint_url
    xml.changefreq "yearly"
    xml.priority "0.3"
  end

  xml.url do
    xml.loc privacy_url
    xml.changefreq "yearly"
    xml.priority "0.3"
  end

  @episodes.each do |episode|
    xml.url do
      xml.loc episode_url(episode)
      xml.lastmod episode.updated_at.iso8601
      xml.changefreq "monthly"
      xml.priority "0.7"
    end
  end
end

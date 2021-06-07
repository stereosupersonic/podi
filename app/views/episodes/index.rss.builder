# https://itunespartner.apple.com/podcasts/articles/podcast-requirements-3058
# https://github.com/simplepie/simplepie-ng/wiki/Spec:-iTunes-Podcast-RSS

xml.instruct!
xml.rss("version" => "2.0",
  "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
  "xmlns:sy" => "http://purl.org/rss/1.0/modules/syndication/",
  "xmlns:admin" => "http://webns.net/mvcb/",
  "xmlns:atom" => "http://www.w3.org/2005/Atom/",
  "xmlns:rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
  "xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd") do
  xml.channel do
    # https://help.apple.com/itc/podcasts_connect/#/itcb54353390

    # The show title.
    xml.title @feed.title

    # The show description. max 4000
    xml.description strip_tags @feed.description

    # The artwork for the show
    xml.tag! "itunes:image", href: @feed.logo_url

    # The language spoken on the show. ISO 639 e.g. en-us
    xml.language @feed.itunes_language

    # The show category information.
    xml.tag! "itunes:category", text: @feed.itunes_category do
      xml.tag! "itunes:category", text: @feed.itunes_sub_category
    end

    # The podcast parental advisory information.
    xml.tag! "itunes:explicit", false

    # The group responsible for creating the show.
    xml.tag! "itunes:author", @feed.author

    # The website associated with a podcast.
    xml.link @feed.canonical_url

    # The podcast owner contact information.
    xml.tag! "itunes:owner" do
      xml.tag! "itunes:name", @feed.owner
      xml.tag! "itunes:email", @feed.email
    end

    # The show title specific for Apple Podcasts.
    # If your show is Serial you must use this tag.
    xml.tag! "itunes:title", @feed.title

    #	The show copyright details.
    xml.copyright @feed.copyright

    # The new podcast RSS Feed URL.
    # xml.tag! "itunes:new-feed-url", episodes_url(:xml)
    xml << render(@feed.episodes)
  end
end

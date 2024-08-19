# Set the host name for URL creation
host = if Rails.env.test?
  "wartenberger.test.com"
elsif Rails.env.development?
  "localhost:3000"
else
  ENV["DEFAULT_URL_HOST"] || "#{ENV.fetch('HEROKU_APP_NAME')}.herokuapp.com"
end

protocol = Rails.application.config.force_ssl ? "https" : "http"

SitemapGenerator::Sitemap.default_host = "#{protocol}://#{host}"

SitemapGenerator::Sitemap.public_path = "tmp/sitemap"
# Where you want your sitemap.xml.gz file to be uploaded.

SitemapGenerator::Sitemap.adapter = SitemapGenerator::AwsSdkAdapter.new(
  Rails.application.config.aws_bucket_name,
  aws_access_key_id: Rails.application.config.aws_access_key,
  aws_secret_access_key: Rails.application.config.aws_secret_key,
  aws_region: Rails.application.config.aws_s3_region
)

# The full path to your bucket
SitemapGenerator::Sitemap.sitemaps_host = "https://#{Rails.application.config.aws_bucket_name}.s3.amazonaws.com"

if Rails.application.config.aws_bucket_name.present?

  SitemapGenerator::Sitemap.create do
    add episodes_path, priority: 0.7, changefreq: "daily"

    Episode.published.each do |episode|
      add episode_path(episode), priority: 0.7, changefreq: "daily", lastmod: episode.updated_at
    end

    add "/about", changefreq: "monthly"
    add "/imprint", changefreq: "monthly"
    add "/privacy", changefreq: "monthly"
  end

else

  Rails.logger.debug "ERROR: aws s3 is not cofigured"

end

desc "clears the cache"
task clear_cache: :environment do
  Rails.cache.clear
end

namespace :active_storage do
  desc "Purges unattached Active Storage blobs. Run regularly."
  task purge_unattached: :environment do
    files = ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at <= ?", 2.days.ago)
    puts "purge: #{files.count} files."
    files.find_each(&:purge_later)
  end

  desc "Serves uploaded mp3s for playing in place instead of as a download. Run once on production."
  task serve_audio_inline: :environment do
    service = ActiveStorage::Blob.service
    blobs = ActiveStorage::Blob.where(content_type: "audio/mpeg", service_name: service.name)
    puts "rewrite: #{blobs.count} mp3s in #{service.bucket.name}."
    ServeAudioInline.call(blobs: blobs, service: service)
    puts "Done. Invalidate the CloudFront cache so the new headers are served."
  end
end

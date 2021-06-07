require "shrine"
require "shrine/storage/cloudinary"
if Rails.env.test?
  require "shrine/storage/memory"
  Shrine.storages = {
    cache: Shrine::Storage::Memory.new, # temporary
    store: Shrine::Storage::Memory.new # permanent
  }
else
  require "cloudinary"

  Cloudinary.config(
    cloud_name: ENV.fetch("CLOUDINARY_CLOUD_NAME"),
    api_key: ENV.fetch("CLOUDINARY_API_KEY"),
    api_secret: ENV.fetch("CLOUDINARY_API_SECRET")
  )

  Shrine.storages = {
    cache: Shrine::Storage::Cloudinary.new(prefix: "cache"),
    store: Shrine::Storage::Cloudinary.new(prefix: Rails.env)
  }

end

Shrine.plugin :activerecord # loads Active Record integration
Shrine.plugin :cached_attachment_data # enables retaining cached file across form redisplays
Shrine.plugin :restore_cached_data # extracts metadata for assigned cached files
Shrine.plugin :validation_helpers
Shrine.plugin :validation
Shrine.plugin :determine_mime_type

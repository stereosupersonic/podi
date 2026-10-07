class ImageUploader < Shrine
  plugin :store_dimensions

  Attacher.validate do
    validate_mime_type %w[image/jpeg image/png image/webp]
  end
end

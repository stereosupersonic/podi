class ImageUploader < Shrine
  # Apple requires square covers of 1400 to 3000 px; Spotify requires 1:1.
  SIDE_RANGE = 1400..3000

  plugin :store_dimensions

  Attacher.validate do
    validate_mime_type %w[image/jpeg image/png image/webp]

    width, height = file.dimensions
    if width.nil? || height.nil?
      errors << "dimensions could not be read"
    elsif width != height
      errors << "must be square (1:1), this image is #{width}×#{height} px"
    elsif !SIDE_RANGE.cover?(width)
      errors << "must be #{SIDE_RANGE.min} to #{SIDE_RANGE.max} px wide, this image is #{width}×#{height} px"
    end
  end
end

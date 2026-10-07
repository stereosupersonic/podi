# S3 keeps the Content-Disposition an object was uploaded with. Copying each mp3 onto itself with
# replaced metadata drops the "attachment" older uploads carry; the audio itself is not touched.
class ServeAudioInline < BaseService
  attr_accessor :blobs, :service

  def call
    blobs.find_each { |blob| copy_onto_itself(blob) }
  end

  private

  def copy_onto_itself(blob)
    object = service.bucket.object(blob.key)
    object.copy_from(object, metadata_directive: "REPLACE", content_type: blob.content_type,
                             **service.upload_options)
  end
end

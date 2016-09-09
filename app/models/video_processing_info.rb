class VideoProcessingInfo
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :started_at, type: Time
  field :completed_at, type: Time
  field :failed_at, type: Time
  field :input_params, type: Hash
  field :output_metadata, type: Hash

  belongs_to :user, inverse_of: :video_processing_infos

  has_mongoid_attached_file :source_file
  validates_attachment_content_type :source_file, content_type: ["video/x-flv", "video/mp4", "application/x-mpegURL", "video/MP2T", "video/3gpp", "video/quicktime", "video/x-msvideo", "video/x-ms-wmv"]
  validates_attachment_presence :source_file

  has_mongoid_attached_file :result_file
  validates_attachment_content_type :result_file, content_type: ["video/x-flv", "video/mp4", "application/x-mpegURL", "video/MP2T", "video/3gpp", "video/quicktime", "video/x-msvideo", "video/x-ms-wmv"]

  state_machine initial: :scheduled do
    state :scheduled
    state :processing
    state :done
    state :failed

    before_transition scheduled: :processing do |vpd|
      vpd.started_at = Time.zone.now
      vpd.failed_at = nil
    end

    before_transition failed: :scheduled do |vpd|
      vpd.started_at = nil
      vpd.failed_at = nil
    end

    before_transition processing: :done do |vpd|
      vpd.completed_at = Time.zone.now
    end

    before_transition processing: :failed do |vpd|
      vpd.failed_at = Time.zone.now
    end

    event :schedule do
      transition :failed => :scheduled
    end

    event :start do
      transition :scheduled => :processing
    end

    event :complete do
      transition :processing => :done
    end

    event :failure do
      transition :processing => :failed
    end
  end
end

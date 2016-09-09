class VideoProcessingInfo
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :started_at, type: Time
  field :completed_at, type: Time
  field :failed_at, type: Time
  field :trim_start, type: Integer
  field :trim_end, type: Integer
  field :source_file_duration, type: Integer
  field :result_file_duration, type: Integer

  belongs_to :user, inverse_of: :video_processing_infos

  validates :trim_start, :trim_end, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  VIDEO_CONTENT_TYPES = ["video/x-flv", "video/mp4", "application/x-mpegURL", "video/MP2T", "video/3gpp", "video/quicktime", "video/x-msvideo", "video/x-ms-wmv"]

  has_mongoid_attached_file :source_file
  validates_attachment_content_type :source_file, content_type: VIDEO_CONTENT_TYPES
  validates_attachment_presence :source_file

  has_mongoid_attached_file :result_file
  validates_attachment_content_type :result_file, content_type: VIDEO_CONTENT_TYPES

  after_post_process do |record|
    if self.source_file?
      movie = FFMPEG::Movie.new(self.source_file.queued_for_write[:original].path)
      self.source_file_duration = movie.duration
    end

    if self.result_file?
      movie = FFMPEG::Movie.new(self.result_file.queued_for_write[:original].path)
      self.result_file_duration = movie.duration
    end
  end

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

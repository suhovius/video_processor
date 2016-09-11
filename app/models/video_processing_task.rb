class VideoProcessingTask
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include GlobalID::Identification # http://guides.rubyonrails.org/active_job_basics.html#globalid

  field :started_at, type: Time
  field :completed_at, type: Time
  field :failed_at, type: Time
  field :trim_start, type: Integer
  field :trim_end, type: Integer
  field :source_video_duration, type: Integer
  field :result_video_duration, type: Integer
  field :last_error, type: String

  belongs_to :user, inverse_of: :video_processing_tasks

  validates :trim_start, :trim_end, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  validate :trim_start_is_not_greater_than_trim_end

  VIDEO_CONTENT_TYPES = ["video/x-flv", "video/mp4", "application/x-mpegURL", "video/MP2T", "video/3gpp", "video/quicktime", "video/x-msvideo", "video/x-ms-wmv"]

  has_mongoid_attached_file :source_video, path: PAPERCLIP_FS_ATTACHMENT_PATH, url: PAPERCLIP_FS_ATTACHMENT_URL
  validates_attachment_content_type :source_video, content_type: VIDEO_CONTENT_TYPES
  validates_attachment_presence :source_video

  has_mongoid_attached_file :result_video, path: PAPERCLIP_FS_ATTACHMENT_PATH, url: PAPERCLIP_FS_ATTACHMENT_URL
  validates_attachment_content_type :result_video, content_type: VIDEO_CONTENT_TYPES

  after_post_process do |record|
    if self.source_video? && self.source_video.queued_for_write[:original]
      movie = FFMPEG::Movie.new(self.source_video.queued_for_write[:original].path)
      self.source_video_duration = movie.duration
    end

    if self.result_video? && self.result_video.queued_for_write[:original]
      movie = FFMPEG::Movie.new(self.result_video.queued_for_write[:original].path)
      self.result_video_duration = movie.duration
    end
  end

  state_machine initial: :scheduled do
    state :scheduled
    state :processing
    state :done
    state :failed

    before_transition scheduled: :processing do |vpt|
      vpt.started_at = Time.zone.now
      vpt.failed_at = nil
    end

    before_transition failed: :scheduled do |vpt|
      vpt.started_at = nil
      vpt.failed_at = nil
    end

    before_transition processing: :done do |vpt|
      vpt.completed_at = Time.zone.now
    end

    before_transition processing: :failed do |vpt|
      vpt.failed_at = Time.zone.now
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

  def enqueue!
    if self.scheduled?
      ::VideoProcessingJob.perform_later(self)
    else
      raise ApiError, I18n.t("api.errors.data.can_not_enqueue")
    end
  end

  def restart!
    self.schedule!
    self.enqueue!
  end

  private
    def trim_start_is_not_greater_than_trim_end
      self.errors.add(:base, I18n.t("mongoid.errors.models.video_processing_task.trim_start_should_be_less_than_trim_end")) if (self.trim_start? && self.trim_end?) && (self.trim_start.to_i >= self.trim_end.to_i)
    end
end

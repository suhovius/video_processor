class VideoProcessingInfo
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

  belongs_to :user, inverse_of: :video_processing_infos

  validates :trim_start, :trim_end, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  VIDEO_CONTENT_TYPES = ["video/x-flv", "video/mp4", "application/x-mpegURL", "video/MP2T", "video/3gpp", "video/quicktime", "video/x-msvideo", "video/x-ms-wmv"]

  # TODO: Refactor this. Remove code duplication for attachments
  has_mongoid_attached_file :source_video
  validates_attachment_content_type :source_video, content_type: VIDEO_CONTENT_TYPES
  validates_attachment_presence :source_video

  has_mongoid_attached_file :result_video
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

    before_transition scheduled: :processing do |vpi|
      vpi.started_at = Time.zone.now
      vpi.failed_at = nil
    end

    before_transition failed: :scheduled do |vpi|
      vpi.started_at = nil
      vpi.failed_at = nil
    end

    before_transition processing: :done do |vpi|
      vpi.completed_at = Time.zone.now
    end

    before_transition processing: :failed do |vpi|
      vpi.failed_at = Time.zone.now
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

  def perform_processing!
    dir_path = "#{::Rails.root}/tmp/video_processing_infos/#{self.id.to_s}"
    begin
      self.start!
      FileUtils.mkdir_p(dir_path)
      source_video_extension = File.extname(self.source_video_file_name)
      source_video_basename = File.basename(self.source_video_file_name, source_video_extension)
      tmp_file_path = "#{dir_path}/#{source_video_basename}_trim_from_#{self.trim_start}_to_#{self.trim_end}#{source_video_extension}"
      movie = FFMPEG::Movie.new(self.source_video.path)
      movie.transcode(tmp_file_path, ["-ss", self.trim_start.to_s, "-t", (self.trim_end - self.trim_start).to_s])
      File.open(tmp_file_path, "r") do |file|
        self.result_video = file
        self.complete!
      end
    rescue FFMPEG::Error => e
      self.last_error = I18n.t("ffmpeg.errors.encoding_failed") # FFMPEG Error message is too much unreadable. Let's use here some user friendly text.
      self.failure!
    rescue Exception => e
      self.last_error = e.message
      self.failure!
    ensure
      FileUtils.rm_rf(dir_path) if Dir.exists?(dir_path)
    end
  end

  def restart!
    self.schedule!
    self.enqueue!
  end
end

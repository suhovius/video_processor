class VideoProcessingTask
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification # http://guides.rubyonrails.org/active_job_basics.html#globalid
  include AASM

  field :started_at, type: Time
  field :completed_at, type: Time
  field :failed_at, type: Time
  field :trim_start, type: Integer
  field :trim_end, type: Integer
  field :source_video_duration, type: Integer
  field :result_video_duration, type: Integer
  field :last_error, type: String
  field :state, type: String

  belongs_to :user, inverse_of: :video_processing_tasks

  validates :trim_start, :trim_end, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  validate :trim_start_is_not_greater_than_trim_end

  mount_uploader :source_video, VideoUploader, mount_on: :source_video_file_name
  validates_presence_of :source_video

  mount_uploader :result_video, VideoUploader, mount_on: :result_video_file_name

  aasm column: 'state' do
    state :scheduled, initial: true
    state :processing
    state :done
    state :failed

    event :schedule do
      before do
        self.started_at = nil
        self.failed_at = nil
      end

      transitions from: :failed, to: :scheduled
    end

    event :start do
      before do
        self.started_at = Time.zone.now
        self.failed_at = nil
      end

      transitions from: :scheduled, to: :processing
    end

    event :complete do
      before do
        self.completed_at = Time.zone.now
      end

      transitions from: :processing, to: :done
    end

    event :failure do
      before do
        self.failed_at = Time.zone.now
      end

      transitions from: :processing, to: :failed
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

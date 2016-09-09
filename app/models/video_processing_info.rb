class VideoProcessingInfo
  include Mongoid::Document
  include Mongoid::Timestamps

  field :started_at, type: Time
  field :completed_at, type: Time
  field :failed_at, type: Time

  belongs_to :user, inverse_of: :video_processing_infos

  state_machine initial: :scheduled do
    state :scheduled
    state :processing
    state :done
    state :failed

    before_transition scheduled: :processing do |vpd|
      vpd.started_at = Time.zone.now
      vpd.failed_at = nil
    end

    before_transition processing: :done do |vpd|
      vpd.completed_at = Time.zone.now
    end

    before_transition processing: :failed do |vpd|
      vpd.failed_at = Time.zone.now
    end

    event :start do
      transition [:scheduled, :failed] => :processing
    end

    event :complete do
      transition :processing => :done
    end

    event :fail do
      transition :processing => :failed
    end
  end
end

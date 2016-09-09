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

  has_mongoid_attached_file :result_file

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

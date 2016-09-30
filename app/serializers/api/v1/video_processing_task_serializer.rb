class Api::V1::VideoProcessingTaskSerializer < ActiveModel::Serializer
  attributes :trim_start, :trim_end, :state, :last_error, :id, :source_video, :result_video
  attributes :started_at, :completed_at, :failed_at, :created_at, :updated_at

  def id
    object.id.to_s
  end

  [:source_video, :result_video].each do |attr_name|
    define_method attr_name do
      {
        url: object.send("#{attr_name}?") ? object.send(attr_name).url : nil,
        duration: object.send("#{attr_name}_duration")
      }
    end
  end

  [:started_at, :completed_at, :failed_at, :created_at, :updated_at].each do |attr_name|
    define_method attr_name do
      object.send("#{attr_name}?") ? object.send(attr_name).to_i : nil
    end
  end

end

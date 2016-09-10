json.id video_processing_task.id.to_s

json.(video_processing_task, :trim_start, :trim_end, :state, :last_error)

[:source_video, :result_video].each do |attr_name|
  json.set! attr_name do
    json.url video_processing_task.send("#{attr_name}?") ? video_processing_task.send(attr_name).url : nil
    json.duration video_processing_task.send("#{attr_name}_duration")
  end
end

[:started_at, :completed_at, :failed_at].each do |attr_name|
  json.set! attr_name, video_processing_task.send("#{attr_name}?") ? video_processing_task.send(attr_name).to_i : nil
end

class MetadataProcessor

  attr_reader :video_processing_task, :attachment_name

  def initialize(video_processing_task, attachment_name)
    @video_processing_task = video_processing_task
    @attachment_name = attachment_name
  end

  def process!
    if video_processing_task.send("#{self.attachment_name}")
      movie = FFMPEG::Movie.new(video_processing_task.send(self.attachment_name).path)
      video_processing_task.update_attribute("#{self.attachment_name}_duration", movie.duration)
    end
  end

end

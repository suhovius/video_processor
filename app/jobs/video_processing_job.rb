class VideoProcessingJob < ApplicationJob
  queue_as :video_processing

  rescue_from(Exception) do |exception|
   # Do something with the exception
  end

  def perform(video_processing_info)
    video_processing_info.perform_processing!
  end
end

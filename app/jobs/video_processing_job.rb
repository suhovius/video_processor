class VideoProcessingJob < ApplicationJob
  queue_as :video_processing

  def perform(video_processing_info)
    video_processing_info.perform_processing!
  end
end

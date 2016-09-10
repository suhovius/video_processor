class VideoProcessingJob < ApplicationJob
  queue_as :video_processing

  def perform(video_processing_task)
    VideoTrimmer.new(video_processing_task).perform!
  end
end

class VideoProcessingJob < ApplicationJob
  queue_as :video_processing

  def perform(video_processing_info)
    VideoTrimmer.new(video_processing_info).perform!
  end
end

class VideoTrimmer
  attr_accessor :video_processing_info

  def initialize(video_processing_info)
    @video_processing_info = video_processing_info
  end

  def perform!
    tmp_dir_path = "#{::Rails.root}/tmp/video_processing_infos/#{video_processing_info.id.to_s}"
    begin
      video_processing_info.start!
      validate_trim_attribute_is_not_greater_than_source_video_duration(:trim_start)
      validate_trim_attribute_is_not_greater_than_source_video_duration(:trim_end)
      FileUtils.mkdir_p(tmp_dir_path)
      source_video_extension = File.extname(video_processing_info.source_video_file_name)
      source_video_basename = File.basename(video_processing_info.source_video_file_name, source_video_extension)
      tmp_file_path = "#{tmp_dir_path}/#{source_video_basename}_trim_from_#{video_processing_info.trim_start}_to_#{video_processing_info.trim_end}#{source_video_extension}"
      movie = FFMPEG::Movie.new(video_processing_info.source_video.path)
      movie.transcode(tmp_file_path, ["-ss", video_processing_info.trim_start.to_s, "-t", (video_processing_info.trim_end - video_processing_info.trim_start).to_s])
      File.open(tmp_file_path, "r") do |file|
        video_processing_info.result_video = file
        video_processing_info.complete!
      end
    rescue FFMPEG::Error => e
      video_processing_info.last_error = I18n.t("ffmpeg.errors.encoding_failed") # FFMPEG Error message is too much unreadable. Let's use here some user friendly text.
      video_processing_info.failure!
    rescue Exception => e
      video_processing_info.last_error = e.message
      video_processing_info.failure!
    ensure
      FileUtils.rm_rf(tmp_dir_path) if Dir.exists?(tmp_dir_path)
    end
  end

  private
    # This validation is made here since we can not validate it during video_processing_info creation as we do not know actual video file duration at that time
    def validate_trim_attribute_is_not_greater_than_source_video_duration(trim_attr_name)
      raise Exception, "#{video_processing_info.class.human_attribute_name(trim_attr_name)} #{I18n.t('mongoid.errors.models.video_processing_info.can_not_be_greater_than_source_video_duration')}" if video_processing_info.send("#{trim_attr_name}?") && video_processing_info.source_video_duration? && video_processing_info.send(trim_attr_name) > video_processing_info.source_video_duration
    end
end

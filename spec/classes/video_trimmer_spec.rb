require 'rails_helper'

RSpec.describe VideoTrimmer do
  context 'instance methods' do
    describe "perform_processing!" do
      context 'when video_processing_info is scheduled' do
        context 'real file processing test' do
          before do
            @video_processing_info = create(:video_processing_info_with_real_file, trim_start: 2, trim_end: 12)
            @video_trimmer = VideoTrimmer.new(@video_processing_info)
          end

          after do
            @video_processing_info.destroy # remove video files
          end

          it "should trim file properly", speed: 'slow' do
            expect { @video_trimmer.perform! }.to change { @video_processing_info.result_video? }.from(false).to(true)
            expect(@video_processing_info.source_video_duration).to eql 15
            expect(@video_processing_info.result_video_duration).to eql 10
            expect(File).to exist(@video_processing_info.result_video.path)

            expect(@video_processing_info).to be_done
          end
        end

        context 'stub real processing test' do
          before do
            @video_processing_info = create(:video_processing_info, trim_start: 3, trim_end: 8)
            @video_trimmer = VideoTrimmer.new(@video_processing_info)
          end

          it "should provide proper trimmig params to ffmpeg" do
            movie = double(:movie)
            expect(FFMPEG::Movie).to receive(:new).with(@video_processing_info.source_video.path).and_return(movie)
            tmp_file_path = "#{::Rails.root}/tmp/video_processing_infos/#{@video_processing_info.id.to_s}/test_video_trim_from_3_to_8.mov"
            expect(movie).to receive(:transcode).with(tmp_file_path, ["-ss", "3", "-t", "5"])

            @video_trimmer.perform!
          end

          context 'when ffmpeg returns error' do
            before do
              expect(FFMPEG::Movie).to receive(:new).with(@video_processing_info.source_video.path).and_raise(FFMPEG::Error)
              @video_trimmer = VideoTrimmer.new(@video_processing_info)
            end

            it "should save it in last_error attribute and set state to failed" do
              expect { @video_trimmer.perform! }.to change { @video_processing_info.reload.state }.from("scheduled").to("failed")
              expect(@video_processing_info.last_error).to eql I18n.t("ffmpeg.errors.encoding_failed")
            end
          end

          context 'when some regular exception happens' do
            let(:exception) { StandardError.new("Some error message #{rand(100)}") }

            before do
              expect(FFMPEG::Movie).to receive(:new).with(@video_processing_info.source_video.path).and_raise(exception)
              @video_trimmer = VideoTrimmer.new(@video_processing_info)
            end

            it "should save it in last_error attribute and set state to failed" do
              expect { @video_trimmer.perform! }.to change { @video_processing_info.reload.state }.from("scheduled").to("failed")
              expect(@video_processing_info.last_error).to eql exception.message
            end
          end

          context 'when trim_start is greater than source_video duration' do
            let(:video_processing_info) { create(:video_processing_info, trim_start: 20, trim_end: 25, source_video_duration: 15) }
            let(:video_trimmer) { VideoTrimmer.new(video_processing_info) }
            it "should save error in last_error attribute and set state to failed" do
              expect { video_trimmer.perform! }.to change { video_processing_info.reload.state }.from("scheduled").to("failed")
              expect(video_processing_info.last_error).to eql "#{video_processing_info.class.human_attribute_name(:trim_start)} #{I18n.t('mongoid.errors.models.video_processing_info.can_not_be_greater_than_source_video_duration')}"
            end
          end

          context 'when trim_end is greater than source_video duration' do
            let(:video_processing_info) { create(:video_processing_info, trim_start: 10, trim_end: 25, source_video_duration: 15) }
            let(:video_trimmer) { VideoTrimmer.new(video_processing_info) }
            it "should save error in last_error attribute and set state to failed" do
              expect { video_trimmer.perform! }.to change { video_processing_info.reload.state }.from("scheduled").to("failed")
              expect(video_processing_info.last_error).to eql "#{video_processing_info.class.human_attribute_name(:trim_end)} #{I18n.t('mongoid.errors.models.video_processing_info.can_not_be_greater_than_source_video_duration')}"
            end
          end
        end
      end
    end
  end
end

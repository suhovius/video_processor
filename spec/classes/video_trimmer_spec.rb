require 'rails_helper'

RSpec.describe VideoTrimmer do
  context 'instance methods' do
    describe "perform_processing!" do
      context 'when video_processing_task is scheduled' do
        context 'real file processing test' do
          before do
            @video_processing_task = create(:video_processing_task, trim_start: 2, trim_end: 12)
            @video_trimmer = VideoTrimmer.new(@video_processing_task)
          end

          after do
            @video_processing_task.destroy # remove video files
          end

          it "should trim file properly", speed: 'slow' do
            expect { @video_trimmer.perform! }.to change { @video_processing_task.result_video? }.from(false).to(true)
            expect(@video_processing_task.source_video_duration).to eql 15
            expect(@video_processing_task.result_video_duration).to eql 10
            expect(File).to exist(@video_processing_task.result_video.path)

            expect(@video_processing_task).to be_done
          end
        end

        context 'stub real processing test' do
          before do
            @video_processing_task = create(:video_processing_task, trim_start: 3, trim_end: 8)
            @video_trimmer = VideoTrimmer.new(@video_processing_task)
          end

          it "should provide proper trimmig params to ffmpeg" do
            movie = double(:movie, :duration => rand(100) + 10)
            expect(FFMPEG::Movie).to receive(:new).with(@video_processing_task.source_video.path).at_least(:once).and_return(movie)
            tmp_file_path = "#{::Rails.root}/tmp/video_processing_tasks/#{@video_processing_task.id.to_s}/test_video_trim_from_3_to_8.mov"
            expect(movie).to receive(:transcode).with(tmp_file_path, ["-ss", "3", "-t", "5"])

            @video_trimmer.perform!
          end

          context 'when ffmpeg returns error' do
            before do
              movie = double(:movie, :duration => rand(100) + 10)
              expect(FFMPEG::Movie).to receive(:new).with(@video_processing_task.source_video.path).at_least(:once).and_return(movie)
              expect(movie).to receive(:transcode).and_raise(FFMPEG::Error)
              @video_trimmer = VideoTrimmer.new(@video_processing_task)
            end

            it "should save it in last_error attribute and set state to failed" do
              expect { @video_trimmer.perform! }.to change { @video_processing_task.reload.state }.from("scheduled").to("failed")
              expect(@video_processing_task.last_error).to eql I18n.t("ffmpeg.errors.encoding_failed")
            end
          end

          context 'when some regular exception happens' do
            let(:exception) { StandardError.new("Some error message #{rand(100)}") }

            before do
              movie = double(:movie, :duration => rand(100) + 10)
              expect(FFMPEG::Movie).to receive(:new).with(@video_processing_task.source_video.path).at_least(:once).and_return(movie)
              expect(movie).to receive(:transcode).and_raise(exception)
              @video_trimmer = VideoTrimmer.new(@video_processing_task)
            end

            it "should save it in last_error attribute and set state to failed" do
              expect { @video_trimmer.perform! }.to change { @video_processing_task.reload.state }.from("scheduled").to("failed")
              expect(@video_processing_task.last_error).to eql exception.message
            end
          end

          context 'when trim_start is greater than source_video duration' do
            let(:video_processing_task) { create(:video_processing_task, trim_start: 20, trim_end: 25, source_video_duration: 15) }
            let(:video_trimmer) { VideoTrimmer.new(video_processing_task) }
            it "should save error in last_error attribute and set state to failed" do
              expect { video_trimmer.perform! }.to change { video_processing_task.reload.state }.from("scheduled").to("failed")
              expect(video_processing_task.last_error).to eql "#{video_processing_task.class.human_attribute_name(:trim_start)} #{I18n.t('mongoid.errors.models.video_processing_task.can_not_be_greater_than_source_video_duration')}"
            end
          end

          context 'when trim_end is greater than source_video duration' do
            let(:video_processing_task) { create(:video_processing_task, trim_start: 10, trim_end: 25, source_video_duration: 15) }
            let(:video_trimmer) { VideoTrimmer.new(video_processing_task) }
            it "should save error in last_error attribute and set state to failed" do
              expect { video_trimmer.perform! }.to change { video_processing_task.reload.state }.from("scheduled").to("failed")
              expect(video_processing_task.last_error).to eql "#{video_processing_task.class.human_attribute_name(:trim_end)} #{I18n.t('mongoid.errors.models.video_processing_task.can_not_be_greater_than_source_video_duration')}"
            end
          end
        end
      end
    end
  end
end

require 'rails_helper'

RSpec.describe VideoProcessingInfo, :type => :model do
  context 'validations' do
    it { should have_mongoid_attached_file(:source_video) }
    it { should have_mongoid_attached_file(:result_video) }
  end

  context 'associations' do
    it { is_expected.to belong_to(:user).as_inverse_of(:video_processing_infos) }
  end

  context 'state machine' do
    it { should have_states :scheduled, :processing, :done, :failed }
    it { should handle_events :start, when: :scheduled }
    it { should handle_events :complete, when: :processing }
    it { should handle_events :failure, when: :processing }
    it { should handle_events :schedule, when: :failed }
    it { should reject_events :start, :failure, :complete, when: :done }
    it { should reject_events :failure, :complete, :start, when: :failed }
    it { should reject_events :start, :schedule, when: :processing }

    context 'transition logic' do
      before do
        @video_processing_info = FactoryGirl.create(:video_processing_info)
      end

      context 'on scheduled to processing' do
        it "should set started_at attribute" do
          time_now = Time.zone.now
          travel_to time_now do
            expect { @video_processing_info.start! }.to change { @video_processing_info.started_at.to_i }.from(0).to(time_now.to_i)
          end
        end
      end

      context 'on failed to scheduled' do
        before do
          @video_processing_info.update_attributes(state: "failed", failed_at: Time.zone.now, started_at: Time.zone.now)
        end

        it "should set started_at and failed_at attributes to nil" do
          expect { @video_processing_info.schedule! }.to change { @video_processing_info.started_at.nil? && @video_processing_info.failed_at.nil? }.from(false).to(true)
        end
      end

      context 'on processing to done' do
        before do
          @video_processing_info.update_attributes(state: "processing", started_at: Time.zone.now - 15.minutes)
        end

        it "should set started_at attribute" do
          time_now = Time.zone.now
          travel_to time_now do
            expect { @video_processing_info.complete! }.to change { @video_processing_info.completed_at.to_i }.from(0).to(time_now.to_i)
          end
        end
      end

      context 'on processing to failed' do
        before do
          @video_processing_info.update_attributes(state: "processing", started_at: Time.zone.now - 15.minutes)
        end

        it "should set started_at attribute" do
          time_now = Time.zone.now
          travel_to time_now do
            expect { @video_processing_info.failure! }.to change { @video_processing_info.failed_at.to_i }.from(0).to(time_now.to_i)
          end
        end
      end
    end
  end

  context 'instance methods' do
    describe "enqueue!" do
      context 'when video_processing_info is scheduled' do
        let(:video_processing_info) { build_stubbed(:video_processing_info, state: "scheduled") }
        it "should insert this task into background queue" do
          expect { video_processing_info.enqueue! }.to enqueue_a(VideoProcessingJob).with(global_id(video_processing_info))
        end
      end

      context 'when video_processing_info is not scheduled' do
        let(:video_processing_info) { build_stubbed(:video_processing_info, state: "done") }
        specify { expect { video_processing_info.enqueue! }.to raise_exception(ApiError, I18n.t("api.errors.data.can_not_enqueue")) }
      end
    end

    describe "perform_processing!" do
      context 'when video_processing_info is scheduled' do
        context 'real file processing test' do
          before do
            @video_processing_info = create(:video_processing_info_with_real_file, trim_start: 2, trim_end: 12)
          end

          after do
            @video_processing_info.destroy # remove video files
          end

          it "should trim file properly", speed: 'slow' do
            expect { @video_processing_info.perform_processing! }.to change { @video_processing_info.result_video? }.from(false).to(true)
            expect(@video_processing_info.source_video_duration).to eql 15
            expect(@video_processing_info.result_video_duration).to eql 10
            expect(File).to exist(@video_processing_info.result_video.path)

            expect(@video_processing_info).to be_done
          end
        end

        context 'stub real processing test' do
          before do
            @video_processing_info = create(:video_processing_info, trim_start: 3, trim_end: 8)
          end

          it "should provide proper trimmig params to ffmpeg" do
            movie = double(:movie)
            expect(FFMPEG::Movie).to receive(:new).with(@video_processing_info.source_video.path).and_return(movie)
            tmp_file_path = "#{::Rails.root}/tmp/video_processing_infos/#{@video_processing_info.id.to_s}/test_video_trim_from_3_to_8.mov"
            expect(movie).to receive(:transcode).with(tmp_file_path, ["-ss", "3", "-t", "5"])

            @video_processing_info.perform_processing!
          end

          context 'when ffmpeg returns error' do
            before do
              expect(FFMPEG::Movie).to receive(:new).with(@video_processing_info.source_video.path).and_raise(FFMPEG::Error)
            end

            it "should save it in last_error attribute and set state to failed" do
              expect { @video_processing_info.perform_processing! }.to change { @video_processing_info.reload.state }.from("scheduled").to("failed")
              expect(@video_processing_info.last_error).to eql I18n.t("ffmpeg.errors.encoding_failed")
            end
          end

          context 'when some regular exception happens' do
            let(:exception) { StandardError.new("Some error message #{rand(100)}") }

            before do
              expect(FFMPEG::Movie).to receive(:new).with(@video_processing_info.source_video.path).and_raise(exception)
            end

            it "should save it in last_error attribute and set state to failed" do
              expect { @video_processing_info.perform_processing! }.to change { @video_processing_info.reload.state }.from("scheduled").to("failed")
              expect(@video_processing_info.last_error).to eql exception.message
            end
          end
        end
      end
    end

    describe "restart!" do
      let(:video_processing_info) { build_stubbed(:video_processing_info, state: "failed") }

      it "should schedule and enqueue failed task" do
        expect(video_processing_info).to receive(:schedule!)
        expect(video_processing_info).to receive(:enqueue!)
        video_processing_info.restart!
      end
    end
  end
end

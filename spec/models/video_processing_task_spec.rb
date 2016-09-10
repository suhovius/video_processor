require 'rails_helper'

RSpec.describe VideoProcessingTask, :type => :model do
  context 'validations' do
    it { should have_mongoid_attached_file(:source_video) }
    it { should have_mongoid_attached_file(:result_video) }

    context 'when trim_start is greater than trim_end' do
      let(:video_processing_task) { build(:video_processing_task, trim_start: 10, trim_end: 3, source_video_duration: 15) }

      it "should not save record and return error" do
        video_processing_task.save
        expect(video_processing_task).to_not be_persisted
        expect(video_processing_task.errors.messages[:base]).to include(I18n.t("mongoid.errors.models.video_processing_task.trim_start_should_be_less_than_trim_end"))
      end
    end
  end

  context 'associations' do
    it { is_expected.to belong_to(:user).as_inverse_of(:video_processing_tasks) }
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
        @video_processing_task = FactoryGirl.create(:video_processing_task)
      end

      context 'on scheduled to processing' do
        it "should set started_at attribute" do
          time_now = Time.zone.now
          travel_to time_now do
            expect { @video_processing_task.start! }.to change { @video_processing_task.started_at.to_i }.from(0).to(time_now.to_i)
          end
        end
      end

      context 'on failed to scheduled' do
        before do
          @video_processing_task.update_attributes(state: "failed", failed_at: Time.zone.now, started_at: Time.zone.now)
        end

        it "should set started_at and failed_at attributes to nil" do
          expect { @video_processing_task.schedule! }.to change { @video_processing_task.started_at.nil? && @video_processing_task.failed_at.nil? }.from(false).to(true)
        end
      end

      context 'on processing to done' do
        before do
          @video_processing_task.update_attributes(state: "processing", started_at: Time.zone.now - 15.minutes)
        end

        it "should set started_at attribute" do
          time_now = Time.zone.now
          travel_to time_now do
            expect { @video_processing_task.complete! }.to change { @video_processing_task.completed_at.to_i }.from(0).to(time_now.to_i)
          end
        end
      end

      context 'on processing to failed' do
        before do
          @video_processing_task.update_attributes(state: "processing", started_at: Time.zone.now - 15.minutes)
        end

        it "should set started_at attribute" do
          time_now = Time.zone.now
          travel_to time_now do
            expect { @video_processing_task.failure! }.to change { @video_processing_task.failed_at.to_i }.from(0).to(time_now.to_i)
          end
        end
      end
    end
  end

  context 'instance methods' do
    describe "enqueue!" do
      context 'when video_processing_task is scheduled' do
        let(:video_processing_task) { build_stubbed(:video_processing_task, state: "scheduled") }
        it "should insert this task into background queue" do
          expect { video_processing_task.enqueue! }.to enqueue_a(VideoProcessingJob).with(global_id(video_processing_task))
        end
      end

      context 'when video_processing_task is not scheduled' do
        let(:video_processing_task) { build_stubbed(:video_processing_task, state: "done") }
        specify { expect { video_processing_task.enqueue! }.to raise_exception(ApiError, I18n.t("api.errors.data.can_not_enqueue")) }
      end
    end

    describe "restart!" do
      let(:video_processing_task) { build_stubbed(:video_processing_task, state: "failed") }

      it "should schedule and enqueue failed task" do
        expect(video_processing_task).to receive(:schedule!)
        expect(video_processing_task).to receive(:enqueue!)
        video_processing_task.restart!
      end
    end
  end
end

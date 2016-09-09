require 'rails_helper'

RSpec.describe VideoProcessingInfo, :type => :model do
  context 'validations' do
    it { should have_mongoid_attached_file(:source_file) }
    it { should have_mongoid_attached_file(:result_file) }
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
end

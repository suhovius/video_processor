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
    end
  end
end

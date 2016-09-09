require 'rails_helper'

RSpec.describe VideoProcessingInfo, :type => :model do
  context 'associations' do
    it { is_expected.to belong_to(:user).as_inverse_of(:video_processing_infos) }
  end
end

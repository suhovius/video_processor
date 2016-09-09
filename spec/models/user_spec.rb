require 'rails_helper'

RSpec.describe User, :type => :model do
  context 'api token generation' do
    it "should generate unique random token for each new user" do
      expect(3.times.map { FactoryGirl.create(:user) }.map(&:api_token).uniq.count).to eql 3
    end
  end

  context 'associations' do
    it { is_expected.to have_many(:video_processing_infos).as_inverse_of(:user).with_dependent(:destroy) }
  end
end

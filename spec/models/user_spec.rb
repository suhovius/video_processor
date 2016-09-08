require 'rails_helper'

RSpec.describe User, :type => :model do
  context 'api token generation' do
    it "should generate unique random token for each new user" do
      expect(3.times.map { FactoryGirl.create(:user) }.map(&:api_token).uniq.count).to eql 3
    end
  end
end

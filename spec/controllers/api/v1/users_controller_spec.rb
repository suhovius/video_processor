require "spec_helper"

describe Api::V1::UsersController, type: :api do
  describe "POST create user" do
    it "should create user and return api token" do
      expect { post "/api/v1/users.json" }.to change { User.count }.by(1)

      expect(last_response.status).to eql http_status_for(:created)

      expect(json["api_token"]).to eql User.last.api_token
    end
  end
end

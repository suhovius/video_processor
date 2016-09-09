require "spec_helper"

describe Api::V1::VideoProcessingInfosController, type: :api do
  describe "POST create" do
    context 'when user is authenticated' do
      before do
        @user = create(:user)
        @auth_params = { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Token.encode_credentials(@user.api_token) }
      end

      context 'with valid params' do
        before do
          @params = {
            "video_processing_info" => {
              "trim_start" => 2,
              "trim_end" => 12,
              "source_file" => fixture_file_upload("#{::Rails.root}/spec/fixtures/videos/test_video.mov", 'video/quicktime')
            }
          }
        end

        it "should create video_processing_info and return it's json data" do
          expect { post "/api/v1/video_processing_infos.json", @params, @auth_params }.to change { @user.video_processing_infos.count }.by(1)

          expect(last_response.status).to eql http_status_for(:created)

          expect(json["trim_start"]).to eql @params["video_processing_info"]["trim_start"]
          expect(json["trim_end"]).to eql @params["video_processing_info"]["trim_end"]

          video_processing_info = @user.video_processing_infos.last

          expect(json["source_file"]["url"]).to eql video_processing_info.source_file.url

          expect(json).to match(video_processing_info_hash(video_processing_info))
        end
      end
    end

  end

  private
    def video_processing_info_hash(video_processing_info)
      {
        "id" => video_processing_info.id.to_s,
        "trim_start" => video_processing_info.trim_start,
        "trim_end" => video_processing_info.trim_end,
        "source_file" => {
          "url" => video_processing_info.source_file.url,
          "duration" => video_processing_info.source_file_duration
        },
        "result_file" => {
          "url" => video_processing_info.result_file? ? video_processing_info.result_file.url : nil,
          "duration" => video_processing_info.result_file_duration
        },
        "started_at" => video_processing_info.started_at? ? video_processing_info.started_at.to_i : nil ,
        "completed_at" => video_processing_info.completed_at? ? video_processing_info.completed_at.to_i : nil,
        "failed_at" => video_processing_info.failed_at? ? video_processing_info.to_i : nil
      }
    end

end

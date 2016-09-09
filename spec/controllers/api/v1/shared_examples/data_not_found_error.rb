RSpec.shared_examples 'return error if data is not found' do |method, url|
  it "should return not found error" do
    send(method, url, @params, @auth_params)

    expect(last_response.status).to eql http_status_for(:not_found)
    expected_error_hash = {
      "error" => I18n.t("api.errors.data.not_found"),
      "details" => {}
    }

    expect(json).to match(expected_error_hash)
  end

end

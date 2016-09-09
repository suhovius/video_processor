RSpec.shared_examples 'return error for unauthorized user' do |method, url, params={}|

  it "should return unauthorized user error" do
    send(method, url, params, {})

    expect(last_response.status).to eql http_status_for(:unauthorized)

    expect(json).to match({ "error" => I18n.t("api.errors.bad_credentials") })
  end

end

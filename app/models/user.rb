class User
  include Mongoid::Document
  include Mongoid::Timestamps
  field :api_token, type: String

  # Assign an API key on create
  before_create do |user|
    user.api_token = generate_api_token
  end

  private
    # Generate a unique API key
    def generate_api_token
      loop do
        token = SecureRandom.base64.tr('+/=', 'Qrt')
        break token unless self.class.where(api_token: token).first
      end
    end
end

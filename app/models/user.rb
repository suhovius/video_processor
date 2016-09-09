class User
  include Mongoid::Document
  include Mongoid::Timestamps
  field :api_token, type: String

  index({ api_token: 1 }, { unique: true, name: "api_token_index" })

  has_many :video_processing_infos, dependent: :destroy

  # Assign an API key on create
  before_create do |user|
    user.api_token = generate_api_token
  end

  private
    # Generate a unique API key
    def generate_api_token
      loop do
        token = SecureRandom.base64.tr('+/=', 'Qrt')
        break token unless self.class.where(api_token: token).exists?
      end
    end
end

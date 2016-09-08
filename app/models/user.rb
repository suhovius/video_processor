class User
  include Mongoid::Document
  field :api_token, type: String
end

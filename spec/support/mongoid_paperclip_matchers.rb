RSpec::Matchers.define :have_mongoid_attached_file do |expected|
  match do |actual|
    have_fields(":#{actual}_content_type", ":#{actual}_file_name", ":#{actual}_file_size", ":#{actual}_updated_at")
  end
end

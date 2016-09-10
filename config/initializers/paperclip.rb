path_part = "system/:class/:attachment/:id_partition/:style/:filename"

PAPERCLIP_FS_ATTACHMENT_PATH = ":rails_root/public/#{path_part}"

PAPERCLIP_FS_ATTACHMENT_URL = "#{ENV['DOMAIN']}/#{path_part}"

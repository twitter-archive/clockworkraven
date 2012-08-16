# Returns a signature for the database (a sha1 hash of the database host and
# name).
module DatabaseSignature
  def self.generate
    conf = Rails.configuration.database_configuration[Rails.env]
    return Digest::SHA1.hexdigest(conf['host'].to_s + conf['database'].to_s)
  end
end

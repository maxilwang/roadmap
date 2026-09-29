class SamlSettingsService
  def self.call
    idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new

    # Option A: From a remote metadata URL
    settings = idp_metadata_parser.parse_remote("https://idp.example.com/metadata")

    # Option B: From a local file (uncomment if you prefer this)
    # settings = idp_metadata_parser.parse(File.read(Rails.root.join("config/saml/idp_metadata.xml")))

    # Override / add your Service Provider settings
    settings.assertion_consumer_service_url = "https://your-app.example.com/saml/consume"
    settings.sp_entity_id                   = "https://your-app.example.com/saml/metadata"
    settings.name_identifier_format         = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

    settings
  end
end

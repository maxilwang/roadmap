# app/services/saml_settings_service.rb
class SamlSettingsService
  def self.call
    settings = OneLogin::RubySaml::Settings.new

    # Identity Provider (Microsoft Entra)
    settings.idp_entity_id           = "https://sts.windows.net/90bb22db-a73a-4971-b7d6-7ca3ef90cf06/"
    settings.idp_sso_service_url     = "https://login.microsoftonline.com/90bb22db-a73a-4971-b7d6-7ca3ef90cf06/saml2"
    settings.idp_slo_service_url     = "https://login.microsoftonline.com/90bb22db-a73a-4971-b7d6-7ca3ef90cf06/saml2"
    settings.idp_sso_service_binding = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
    settings.idp_cert                = File.read(Rails.root.join("config", "saml", "idp_cert.pem"))

    # Service Provider (must match Entra exactly)
    settings.sp_entity_id                   = "http://172.27.137.197:3000/saml/metadata"
    settings.assertion_consumer_service_url = "http://172.27.137.197:3000/saml/consume"
    settings.name_identifier_format         = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

    settings
  end
end

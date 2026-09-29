class SamlController < ApplicationController
  # Skip CSRF for the consume endpoint (SAML responses come via POST from the IdP)
  skip_before_action :verify_authenticity_token, only: [:consume]

  # 1. Start SSO (SP-initiated)
  def init
    request = OneLogin::RubySaml::Authrequest.new
    redirect_to(request.create(saml_settings), allow_other_host: true)
  end

  # 2. Consume the SAML Response (Assertion Consumer Service)
  def consume
    response = OneLogin::RubySaml::Response.new(
      params[:SAMLResponse],
      settings: saml_settings
    )

    if response.is_valid?
      # Success – extract user attributes
      email     = response.nameid
      firstname = response.attributes["first_name"] || response.attributes["givenName"]
      lastname  = response.attributes["last_name"]  || response.attributes["sn"]

      # Find or create the user and sign them in
      user = User.find_or_create_by(email: email) do |u|
        u.firstname = firstname
        u.surname   = lastname
      end

      sign_in(user)   # Devise example
      redirect_to root_path
    else
      # Invalid response
      logger.error "SAML Error: #{response.errors.join(', ')}"
      redirect_to root_path, alert: "Authentication failed"
    end
  end

  # 3. Optional: Provide SP Metadata
  def metadata
    meta = OneLogin::RubySaml::Metadata.new
    render xml: meta.generate(saml_settings), content_type: "application/samlmetadata+xml"
  end
end

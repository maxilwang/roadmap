class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:consume]
  # If you require login globally, also skip it here, e.g.:
  # skip_before_action :authenticate_user!, only: [:init, :consume, :metadata]

  CLAIM_EMAIL   = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress".freeze
  CLAIM_GIVEN   = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname".freeze
  CLAIM_SURNAME = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname".freeze

  # 1. Start SSO (SP-initiated)
  def init
    auth_request = OneLogin::RubySaml::Authrequest.new
    redirect_to auth_request.create(saml_settings), allow_other_host: true
  end

  # 2. Assertion Consumer Service
  def consume
    saml_response = OneLogin::RubySaml::Response.new(
      params[:SAMLResponse],
      settings: saml_settings
    )

    if saml_response.is_valid?
      attrs = saml_response.attributes

      email     = (attrs[CLAIM_EMAIL] || saml_response.nameid).to_s.downcase
      firstname = attrs[CLAIM_GIVEN]
      lastname  = attrs[CLAIM_SURNAME]

      user = User.find_or_initialize_by(email: email)
      if user.new_record?
        user.firstname = firstname
        user.surname   = lastname
        user.password  = Devise.friendly_token[0, 20] # Devise requires one
        user.save!
      end

      sign_in(user)
      redirect_to root_path
    else
      logger.error "SAML Error: #{saml_response.errors.join(', ')}"
      redirect_to root_path, alert: "Authentication failed"
    end
  end

  # 3. SP metadata (give this to Entra if you like)
  def metadata
    meta = OneLogin::RubySaml::Metadata.new
    render xml: meta.generate(saml_settings), content_type: "application/samlmetadata+xml"
  end

  private

  def saml_settings
    SamlSettingsService.call
  end
end

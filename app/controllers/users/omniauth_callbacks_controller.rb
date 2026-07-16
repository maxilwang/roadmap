class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

 #def shibboleth
   #Rails.logger.debug "=== UID: #{request.env['omniauth.auth']&.uid.inspect}"
    #Rails.logger.debug "=== HTTP_SAMACCOUNTNAME: #{request.env['HTTP_SAMACCOUNTNAME'].inspect}"
    #Rails.logger.debug "=== HTTP_MAIL: #{request.env['HTTP_MAIL'].inspect}" 
  #require 'pry'
  ##
  # Dynamically build a handler for each omniauth provider
  # -------------------------------------------------------------
  IdentifierScheme.where(active: true).each do |scheme|
    define_method(scheme.name.downcase) do
      handle_omniauth(scheme)
    end
  end
  
  ##
  # Processes callbacks from an omniauth provider and directs the user to 
  # the appropriate page:
  #   Not logged in and uid had no match ---> Sign Up page
  #   Not logged in and uid had a match ---> Sign In and go to Home Page
  #   Signed in and uid had no match --> Save the uid and go to the Profile Page
  #   Signed in and uid had a match --> Go to the Home Page
  #
  # @scheme [IdentifierScheme] The IdentifierScheme for the provider
  # -------------------------------------------------------------
  def handle_omniauth(scheme)
    # TEMP DEBUG
    Rails.logger.debug "=== omniauth.auth: #{request.env['omniauth.auth'].inspect}"
    Rails.logger.debug "=== HTTP_EPPN: #{request.env['HTTP_EPPN'].inspect}"
    Rails.logger.debug "=== HTTP_REMOTE_USER: #{request.env['HTTP_REMOTE_USER'].inspect}"
    Rails.logger.debug "=== HTTP_MAIL: #{request.env['HTTP_MAIL'].inspect}"
    Rails.logger.debug "=== HTTP_SHIB_SESSION_ID: #{request.env['HTTP_SHIB_SESSION_ID'].inspect}"
    Rails.logger.debug "=== REMOTE_USER: #{request.env['REMOTE_USER'].inspect}"
    #Rails.logger.info "CURRENT USER ID: #{current_user.id}"
    # END DEBUG
    #user = User.from_omniauth(request.env["omniauth.auth"].nil? ? request.env : request.env["omniauth.auth"])
    auth_data = request.env["omniauth.auth"].nil? ? request.env : request.env["omniauth.auth"]
    Rails.logger.debug "=== from_omniauth uid: #{auth_data.uid rescue auth_data['uid']} | provider: #{auth_data.provider rescue auth_data['provider']}"
    Rails.logger.debug "=== from_omniauth class: #{auth_data.class}"
    user = User.from_omniauth(auth_data)
    Rails.logger.debug "=== from_omniauth result: user_id=#{user&.id} email=#{user&.email}"
    # If the user isn't logged in
    if current_user.nil? 
      # If the uid didn't have a match in the system send them to register
      if user.nil?
        session["devise.#{scheme.name.downcase}_data"] = request.env["omniauth.auth"]
        redirect_to new_user_registration_url
        
      # Otherwise sign them in
      else
        # Until ORCID becomes supported as a login method
        if scheme.name == 'shibboleth'
          #set_flash_message(:notice, :success, kind: scheme.description) if is_navigational_format?
          #sign_in_and_redirect user, event: :authentication
          sign_in_and_redirect user, event: :authentication
          #binding.remote_pry
          set_flash_message(:notice, :success, kind: scheme.description) if is_navigational_format?
          #if UserIdentifier.create(identifier_scheme: scheme, 
          #                       identifier: request.env["omniauth.auth"].uid,
          #                       user: current_user)
          #  flash[:notice] = _('Your account has been successfully linked to %{scheme}.') % { scheme: scheme.description }
          #else
          #  flash[:alert] = _('Unable to link your account to %{scheme}.') % { scheme: scheme.description }
          #end
          #redirect_to plans_url
        else
          flash[:notice] = t('identifier_schemes.new_login_success')
          redirect_to new_user_registration_url
          #redirect_to plans_url
        end
      end
      
    # The user is already logged in and just registering the uid with us
    else
      # If the user could not be found by that uid then attach it to their record
      if user.nil?
        if UserIdentifier.create(identifier_scheme: scheme, 
                                 identifier: request.env["omniauth.auth"].uid,
                                 user: current_user)
                               
          flash[:notice] = _('Your account has been successfully linked to %{scheme}.') % { scheme: scheme.description }
        else
          flash[:alert] = _('Unable to link your account to %{scheme}.') % { scheme: scheme.description }
        end
        
      else
        # If a user was found but does NOT match the current user then the identifier has
        # already been attached to another account (likely the user has 2 accounts)
        identifier = UserIdentifier.where(identifier: request.env["omniauth.auth"].uid).first
        if identifier.user.id != current_user.id
          flash[:alert] =  _("The current #{scheme.description} iD has been already linked to a user with email #{identifier.user.email}")
        end
        
        # Otherwise, the identifier was found and it matches the one already associated 
        # with the current user so nothing else needs to be done
      end

      # Redirect to the User Profile page
      redirect_to edit_user_registration_path
    end
  end

  # -------------------------------------------------------------
  def failure
    redirect_to root_path
  end
end

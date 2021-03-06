#lib_dir = File.expand_path("..", __FILE__)
#$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "kaui/engine"

module Kaui

  mattr_accessor :home_path
  mattr_accessor :tenant_home_path
  mattr_accessor :new_user_session_path
  mattr_accessor :destroy_user_session_path

  mattr_accessor :bundle_key_display_string
  mattr_accessor :creditcard_plugin_name
  mattr_accessor :layout

  mattr_accessor :thread_pool

  mattr_accessor :demo_mode

  mattr_accessor :root_username
  mattr_accessor :root_password
  mattr_accessor :root_api_key
  mattr_accessor :root_api_secret

  mattr_accessor :default_roles

  # Pre-pending relative_url_root seems required when deploying in Tomcat sub-paths (not needed for session routes below though)
  self.home_path = lambda { ActionController::Base.relative_url_root.to_s + Kaui::Engine.routes.url_helpers.home_path }
  self.tenant_home_path = lambda { ActionController::Base.relative_url_root.to_s + Kaui::Engine.routes.url_helpers.tenants_path }

  self.new_user_session_path = lambda { Kaui::Engine.routes.url_helpers.new_user_session_path }
  self.destroy_user_session_path = lambda { Kaui::Engine.routes.url_helpers.destroy_user_session_path }

  self.bundle_key_display_string =  lambda {|bundle_key| bundle_key }
  self.creditcard_plugin_name =  lambda { '__EXTERNAL_PAYMENT__' }

  self.demo_mode = false

  # Root credentials for SaaS operations
  self.root_username = 'admin'
  self.root_password = 'password'
  self.root_api_key = 'bob'
  self.root_api_secret = 'lazar'

  # Default roles for sign-ups
  self.default_roles = ['tenant_admin']

  def self.is_user_assigned_valid_tenant?(user, session)
    #
    # If those are set in config initializer then we bypass the check
    # For multi-tenant production deployment, those should not be set!
    #
    return true if KillBillClient.api_key.present? && KillBillClient.api_secret.present?

    # Not tenant in the session, returns right away...
    return false if session[:kb_tenant_id].nil?

    # Signed-out?
    return false if user.nil?

    # If there is a kb_tenant_id in the session then we check if the user is allowed to access it
    au = Kaui::AllowedUser.find_by_kb_username(user.kb_username)
    return false if au.nil?

    return au.kaui_tenants.select { |t| t.kb_tenant_id == session[:kb_tenant_id] }.first
  end

  def self.current_tenant_user_options(user, session)
    kb_tenant_id = session[:kb_tenant_id]
    user_tenant = Kaui::Tenant.find_by_kb_tenant_id(kb_tenant_id) if kb_tenant_id
    result = {
        :username => user.kb_username,
        :password => user.password,
        :session_id => user.kb_session_id,
    }
    if user_tenant
      result[:api_key] = user_tenant.api_key
      result[:api_secret] = user_tenant.api_secret
    end
    result
  end




  def self.config(&block)
    {
      :layout => layout || 'kaui/layouts/kaui_application',
    }
  end
end

# ruby-1.8 compatibility
module Kernel
  def define_singleton_method(*args, &block)
    class << self
      self
    end.send(:define_method, *args, &block)
  end
end

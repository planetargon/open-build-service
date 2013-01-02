# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger        = SyslogLogger.new
config.log_level = :debug

# Full error reports are disabled and caching is turned on
config.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors if you bad email addresses should just be ignored
# config.action_mailer.raise_delivery_errors = false

CONFIG['proxy_auth_mode'] = :on


############################################################################
# NOTE: CONFIG variables are no longer used for LDAP.
# These are now stored in the database, and can be managed through the webui
############################################################################
CONFIG['ldap_mode'] = :off
# LDAP Servers separated by ':'.
# OVERRIDE with your company's ldap servers. Servers are picked randomly for
# each connection to distribute load.
CONFIG['ldap_servers'] = "ldap1.mycompany.com:ldap2.mycompany.com"
# OVERRIDE with your company's ldap search base for the users who will use OBS
CONFIG['ldap_search_base'] = "OU=Organizational Unit,DC=Domain Component"
# Sam Account Name is the login name for LDAP
LCONFIG['dap_search_attr'] = "sAMAccountName"
# Max number of times to attempt to contact the LDAP servers
CONFIG['max_ldap_attempts'] = 10

CONFIG['source_host'] = "storage"
CONFIG['source_port'] = 5352
CONFIG['source_protocol'] = "http"

CONFIG['extended_backend_log'] = false

#ActionController::AbstractRequest.relative_url_root = "/stage"

require 'hermes'
Hermes::Config.setup do |hermesconf|
  hermesconf.dbhost = 'storage'
  hermesconf.dbuser = 'hermes'
  hermesconf.dbpass = ''
  hermesconf.dbname = 'hermes'
end

CONFIG['response_schema_validation'] = true

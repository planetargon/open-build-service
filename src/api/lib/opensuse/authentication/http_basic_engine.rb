module Opensuse
  module Authentication
    class HttpBasicEngine
      include Opensuse::Authentication::Logger
      include Opensuse::Authentication::HttpHeader

      attr_reader :configuration, :environment
      attr_accessor :user_login

      def initialize(configuration, environment)
        @configuration = configuration
        @environment = environment
      end

      def authenticate
        authorization = extract_authorization_from_header

        logger.send :debug, "AUTH: #{authorization.inspect}"

        user = nil

        if ApplicationSettings::AuthAllowAnonymous.get.value
          read_only_hosts = Array(ApplicationSettings::AuthReadOnlyHosts.get.value) || []
          read_only_hosts << ApplicationSettings::AuthWebuiHost.get.value if ApplicationSettings::AuthWebuiHost.get.value # This was used in config files until OBS 2.1

          if read_only_hosts.include?(environment['REMOTE_HOST']) || read_only_hosts.include?(environment['REMOTE_ADDR'])
            if environment['HTTP_USER_AGENT'] && environment['HTTP_USER_AGENT'].match(/^(obs-webui|obs-software)/)
             return user = User.find_by_login("_nobody_")
            end
          else
            logger.send :error, "Anonymous configured, but #{read_only_hosts.inspect} does not include '#{environment['REMOTE_HOST']} '#{environment['REMOTE_ADDR']}'}'"
          end
        end

        if authorization && authorization[0] == "Basic"
          login, password = Base64.decode64(authorization[1]).split(':', 2)[0..1]

          @user_login = login

          user = User.find_with_credentials(login, password)

          if user.nil?
            [nil, "Unknown user '#{login}' or invalid password"]
          else
            user
          end
        else
          logger.send :debug, "No authentication string was sent"
          [nil, "Authentication required"]
        end
      end
    end
  end
end
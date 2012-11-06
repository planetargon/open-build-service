module Opensuse
  module Authentication
    class HttpBasicEngine
      include Opensuse::Authentication::Logger

      attr_reader :configuration, :environment
      attr_accessor :user_login

      def initialize(configuration, environment)
        @configuration = configuration
        @environment = environment
      end

      def authenticate
        read_only_hosts = Array(configuration['read_only_hosts']) || []
        read_only_hosts << configuration['webui_host'] if configuration['webui_host'] # This was used in config files until OBS 2.1

        if read_only_hosts.include?(environment['REMOTE_HOST']) || read_only_hosts.include?(environment['REMOTE_ADDR'])
          if environment['HTTP_USER_AGENT'] && environment['HTTP_USER_AGENT'].match(/^(obs-webui|obs-software)/)
           return User.find_by_login("_nobody_")
          end
        else
          logger.send :error, "Anonymous configured, but #{read_only_hosts.inspect} does not include '#{environment['REMOTE_HOST']} '#{environment['REMOTE_ADDR']}'}'"
        end

        logger.send :info, "No authentication string was sent"
        return [nil, "Authentication required"]
      end
    end
  end
end
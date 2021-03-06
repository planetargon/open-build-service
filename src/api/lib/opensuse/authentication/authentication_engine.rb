module Opensuse
  module Authentication
    class AuthenticationEngine
      attr_reader :configuration, :environment, :engine

      def initialize(configuration, environment)
        @configuration = configuration
        @environment = environment
        @engine = determine_engine
      end

      def authenticate
        if engine.respond_to?(:authenticate)
          engine.authenticate
        else
          raise "Engine #{engine.class.to_s} does not respond to authenticate method"
        end
      end

      private
        def determine_engine
          if ApplicationSettings::AuthCrowdMode.get.value && ApplicationSettings::AuthCrowdServer.get.value && ApplicationSettings::AuthCrowdAppName.get.value && ApplicationSettings::AuthCrowdAppPassword.get.value &&
            environment_contains_valid_headers?
            Opensuse::Authentication::CrowdEngine.new(configuration, environment)
          elsif ['on', 'simulate'].include?([ApplicationSettings::AuthIchainMode.get.value, ApplicationSettings::AuthProxyMode.get.value].reject { |v| v.blank? }.uniq.last)
            Opensuse::Authentication::IchainEngine.new(configuration, environment)
          elsif environment_contains_valid_headers? && ApplicationSettings::LdapMode.get.value
            Opensuse::Authentication::LdapEngine.new(configuration, environment)
          elsif environment_contains_valid_headers?
            Opensuse::Authentication::CredentialsEngine.new(configuration, environment)
          elsif ApplicationSettings::AuthAllowAnonymous.get.value
            Opensuse::Authentication::AnonymousEngine.new(configuration, environment)
          end
        end

        def environment_contains_valid_headers?
          ["X-HTTP-Authorization", "Authorization", "HTTP_AUTHORIZATION"].any? { |header| environment.keys.include?(header) }
        end
    end
  end
end
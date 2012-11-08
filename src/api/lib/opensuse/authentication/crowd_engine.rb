module Opensuse
  module Authentication
    class CrowdEngine
      include Opensuse::Authentication::Logger

      attr_reader :configuration, :environment
      attr_accessor :user_login

      def initialize(configuration, environment)
        @configuration = configuration
        @environment = environment
      end

      def authenticate

      end
    end
  end
end
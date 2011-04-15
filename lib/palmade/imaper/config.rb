require 'yaml'

module Palmade
  module Imaper
    class Config
      attr_reader :config

      def initialize
        @config = { }
      end

      def load_file!(config_file)
        @config = YAML.load_file(config_file)

        raise "No accounts configured" unless @config.include?('accounts')

        @config
      end

      # Override this method, to retrieve account configuration from
      # another source. E.g. mongo db or mysql database.
      #
      def select_account(account_name)
        account_name = account_name.to_s

        if config['accounts'].include?(account_name)
          config['accounts'][account_name].symbolize_keys
        else
          raise "Account #{account_name} not defined."
        end
      end
    end
  end
end

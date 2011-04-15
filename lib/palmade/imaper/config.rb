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
      end

      # Override this method, to retrieve mailbox configuration from
      # another source. E.g. mongo db or mysql database.
      #
      def select_mailbox(mb_name)
        mb_name = mb_name.to_s

        if config['mailboxes'].include?(mb_name)
          config['mailboxes'][mb_name].symbolize_keys
        else
          raise "Mailbox #{mb_name} not defined."
        end
      end
    end
  end
end

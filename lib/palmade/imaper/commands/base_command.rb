module Palmade::Imaper
  module Commands
    class BaseCommand
      attr_reader :cli, :config, :argv

      def initialize(cli)
        @cli = cli
        @config = cli.config
        @argv = cli.argv
      end

      def run!(cmd_options = { })
        raise "Not yet implemented"
      end

      protected

      def require_account!(cmd_options)
        raise "Account required, please specify one" unless cmd_options.include?(:account_name)
      end

      def connect_account(account_config, &block)
        puts "Connecting... #{account_config[:address]}"
        $stdout.flush

        conn = Palmade::Imaper::Conn.new(account_config)
        conn.connect!

        if block_given?
          begin
            yield conn
          ensure
            conn.disconnect!
          end
        else
          conn
        end
      end

      def display_email(email)
        subject = email.header['Subject'].to_s
        subject = "%s..." % subject if subject.length > 50

        puts sprintf("  * %s %s %d %s\n    %s %s\n\n",
                     email.uid,
                     email.header['Date'].date_time.utc.to_s(:db),
                     email.size,
                     email.flags.inspect,
                     email.header['From'].addresses.inspect,
                     subject)
      end

      def parse_command_arguments
        args = { }
        argv.each do |a|
          if a =~ /\A([a-zA-Z][a-zA-Z0-9]+)\s*\=\s*(.+)\s*\Z/
            args[$~[1].to_sym] = $~[2]
          end
        end
        args
      end
    end
  end
end

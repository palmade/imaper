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

      def require_mailbox!(cmd_options)
        raise "Mailbox required, please specify one" unless cmd_options.include?(:mb_name)
      end

      def connect_mailbox(mb_config, &block)
        puts "Connecting... #{mb_config[:address]}"
        $stdout.flush

        conn = Palmade::Imaper::Conn.new(mb_config)
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
    end
  end
end

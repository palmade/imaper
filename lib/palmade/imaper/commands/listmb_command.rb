module Palmade::Imaper
  module Commands
    class ListmbCommand < BaseCommand
      def run!(cmd_options)
        require_account!(cmd_options)

        account_config = config.select_account(cmd_options[:account_name])

        connect_account(account_config) do |conn|
          mbs = conn.list_mailboxes
          unless mbs.nil? || mbs.empty?
            mbs = mbs.sort { |mb1, mb2| mb1.name <=> mb2.name }

            mbs.each do |mb|
              puts "%s %s" % [ mb.name, mb.attr ]
            end
          else
            puts "Found no mailboxes. Weird?!"
          end
        end
      end
    end
  end
end

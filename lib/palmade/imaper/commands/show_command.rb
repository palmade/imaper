module Palmade::Imaper
  module Commands
    class ShowCommand < BaseCommand
      def run!(cmd_options)
        require_account!(cmd_options)
        args = parse_command_arguments

        if args.include?(:uids)
          uids = args[:uids].split(/\s*\,\s*/).collect { |u| u.to_i }
        else
          raise "Please specify the uids to show"
        end

        if cmd_options.include?(:mailbox_path)
          mb_path = cmd_options[:mailbox_path]
        else
          mb_path = nil
        end

        account_config = config.select_account(cmd_options[:account_name])

        connect_account(account_config) do |conn|
          unless mb_path.nil?
            puts "Selecting #{mb_path}"

            conn.select(mb_path)
          end

          emails = conn.find_uids(uids).ok![0]
          emails.each do |email|
            puts "\n=== UID: #{email.uid} SIZE: #{email.size} FLAGS: #{email.flags}"
            puts email.header.to_s
            puts "\n"
          end unless emails.nil?
        end
      end
    end
  end
end

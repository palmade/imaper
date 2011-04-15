module Palmade::Imaper
  module Commands
    class ListCommand < BaseCommand
      def run!(cmd_options)
        require_account!(cmd_options)

        case argv[1]
        when 'unseen'
          query = [ 'UNKEYWORD', :seen ]
        when 'seen'
          query = [ 'KEYWORD', :seen ]
        when 'parsed'
          query = [ 'KEYWORD', :parsed ]
        when 'unparsed'
          query = [ 'UNKEYWORD', :parsed ]
        when nil, ''
          query = [ 'ALL' ]
        when /\A\d+/
          query = argv[1].split(',').collect { |uid| uid.to_i }
        else
          raise "Unsupported filter #{argv[1]}"
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

          case query[0]
          when String
            # convert flag to actual IMAP flag
            query[1] = conn.flags[query[1]] unless query[1].nil?

            uids = conn.imap.uid_search(query)
          when Integer
            uids = query
          end

          unless uids.nil? || uids.empty?
            puts "Found #{uids.size} e-mails"

            # let's set the ordering
            if cmd_options[:order] == :desc
              uids = uids.reverse
              puts "  ** reverse order (latest first)"
            end

            if uids.size > cmd_options[:count]
              puts "  ** only showing #{cmd_options[:count]} at a time"

              limit = cmd_options[:count]
            else
              limit = uids.size
            end

            puts "  ** starting offset %d" % cmd_options[:start] if cmd_options[:start] > 0

            puts "\n"
            $stdout.flush

            emails = conn.find_uids(uids.slice(cmd_options[:start], limit)).ok![0]
            emails.each do |email|
              display_email(email)
            end
          else
            puts "Found no e-mails"
          end
        end
      end
    end
  end
end

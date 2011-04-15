module Palmade::Imaper
  module Commands
    class MarkCommand < BaseCommand
      def run!(cmd_options)
        require_mailbox!(cmd_options)

        store = [ ]
        case argv[0]
        when 'mark'
          store[0] = '+FLAGS'
        when 'unmark'
          store[0] = '-FLAGS'
        else
          raise "Failure, wrong command #{argv[0]}"
        end

        case argv[1]
        when 'seen'
          store[1] = [ :seen ]
        when 'parsed'
          store[1] = [ :parsed ]
        when nil, ''
          raise "Please specify a flag to mark"
        else
          raise "Unsupported flag #{argv[1]}"
        end

        unless argv[2].nil? || argv[2].empty?
          uids = argv[2].split(',').collect { |uid| uid.to_i }
        else
          raise "No uids specified"
        end

        mb_config = config.select_mailbox(cmd_options[:mb_name])

        connect_mailbox(mb_config) do |conn|
          unless store[1].nil?
            store[1] = store[1].collect { |fk| conn.flags[fk] }
          end

          conn.imap.uid_store(uids, *store)
          puts "  ! updated #{uids.inspect} with #{store.inspect}"
        end
      end
    end
  end
end

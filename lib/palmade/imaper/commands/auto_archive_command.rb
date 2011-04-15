module Palmade::Imaper
  module Commands
    class AutoArchiveCommand < BaseCommand
      # How this works:
      #
      # Connects to a mailbox, and goes through your e-mails,
      # in oldest to newest order.
      #
      # * Gets the arrival time to this mailbox.
      # * Checks if it's already 'expired' and for 'archiving'
      # * Archives the e-mail to a sub-folder.
      #
      # Notes:
      #
      # * Expiry duration is configurable in hours. (default: 24 hours)
      # * Filing strategy, either daily, or monthly.
      #
      # Invocation line:
      #
      # * imapercli auto_archive 24 daily
      #
      # -- which means, archive e-mails older than 24 hours, and
      #    file e-mails in daily folders.
      #

      DEFAULT_EXPIRY = 24
      DEFAULT_FILING = :monthly
      DEFAULT_BATCH_LIMIT = 25

      def run!(cmd_options)
        args = parse_command_arguments

        case args[:expiry]
        when /\d+/
          expiry = args[:expiry].to_i
          if expiry <= 0 || expiry >= 10000
            raise "Ouch, expiry seems to be way off the scale. Use a number between 1 and 10000"
          end
        when nil, ''
          expiry = DEFAULT_EXPIRY
        else
          raise "Invalid expiry value. Must be number of hours."
        end

        case args[:filing]
        when /\Ad(aily)?\Z/
          filing = :daily
        when /\Am(onthly)\Z/
          filing = :monthly
        when nil, ''
          filing = DEFAULT_FILING
        else
          raise "Unknown filing strategy. Use either monthly or daily."
        end

        case args[:limit]
        when /\d+/
          limit = args[:limit].to_i
          if limit <= 0 || limit >= 500
            raise "Ouch, limit is too much. Specify a number between 1 and 500."
          end
        when nil, ''
          limit = DEFAULT_BATCH_LIMIT
        else
          raise "Unsupported batch limit. Specify the number of e-mails to process in this batch."
        end

        mb_config = config.select_mailbox(cmd_options[:mb_name])

        connect_mailbox(mb_config) do |conn|
          now = Time.now.utc
          expire_at = now - (expiry * 60)

          puts "  ** Auto archiving e-mails with expiry #{expiry}h, filing #{filing}, limit #{limit}"
          puts "  ** check e-mails older than #{expire_at.to_s(:rfc2822)}"

          case args[:uids]
          when String
            uids = args[:uids].split(/\s*\,\s*/).collect { |uid| uid.to_i }
          when nil, ''
            uids = conn.imap.uid_search([ 'ALL' ])
          else
            raise "Unsupported uids params. Specify a list of uid, separated by a comma."
          end

          unless uids.nil? || uids.empty?
            puts "\n"
            puts "Found #{uids.size} e-mails"
            puts "  ** only working #{limit} at a time" if uids.size > limit

            uids = uids.slice(0, limit)
            emails = conn.find_uids(uids).ok![0]
            emails.each do |email|
              at = email.received_time

              unless at.nil?
                if at < expire_at
                  puts "  Archiving #{email.display_line}"
                end
              else
                puts "  ! Skipping #{email.uid}, can't figure out received time"
              end
            end
          else
            puts "Found no e-mails"
          end
        end
      end

      protected


    end
  end
end


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

      DEFAULT_EXPIRY = 48
      DEFAULT_FILING = :daily
      DEFAULT_BATCH_LIMIT = 25

      def run!(cmd_options)
        require_account!(cmd_options)

        args = parse_command_arguments

        case args[:expiry]
        when /\d+/
          expiry = args[:expiry].to_i
          if expiry < 0 || expiry >= 10000
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

        case args[:uids]
        when String
          uids = args[:uids].split(/\s*\,\s*/).collect { |uid| uid.to_i }
        when nil, ''
          uids = nil
        else
          raise "Unsupported uids params. Specify a list of uid, separated by a comma."
        end

        case args[:continuous]
        when /\d+/
          continuous = args[:continuous].to_i
          if continuous < 0 || continuous >= 10
            raise "Either specify a value between 0 and 10 seconds"
          end

          puts "\n!! Will run this command continuously, until you hit Ctrl-C\n\n"

        when nil, ''
          continous = nil
        else
          raise "Ooho, wrong continuous value. Specify the amount of sleep, in-between cycle"
        end

        loop do
          perform_auto_archive(cmd_options[:account_name],
                               :expiry => expiry,
                               :filing => filing,
                               :limit => limit,
                               :uids => uids,
                               :dry_run => cmd_options[:dry_run])

          if continuous.nil?
            break
          else
            puts "\n"
            puts "!! Sleeping for #{continuous} sec(s). Press Ctrl-C to abort at this point, without fear of losing data"
            puts "\n"

            old_trap = Signal.trap('INT') do
              puts "!! Ok, waking up and quitting!"
              continuous = nil

              Process.kill('ALRM', $$)
            end

            # let's have ruby clean-up, from the our last excursion.
            GC.start

            # time to sleep!
            sleep(continuous)

            # return previous handler
            Signal.trap('INT', old_trap)

            # let's try to break, if we were interrupted while, we were at sleep.
            break if continuous.nil?
          end
        end
      end

      protected

      def perform_auto_archive(account_name, params = { })
        expiry = params[:expiry]
        filing = params[:filing]
        limit = params[:limit]
        uids = params[:uids]
        dry_run = params[:dry_run]

        account_config = config.select_account(account_name)

        connect_account(account_config) do |conn|
          now = Time.now.utc
          expire_at = now - (expiry * (60 * 60))

          puts "  ** Auto archiving e-mails with expiry #{expiry}h, filing #{filing}, limit #{limit}"
          puts "  ** check e-mails older than #{expire_at.to_s(:rfc2822)}"

          if dry_run
            puts "  ** !!! Dry running, will not actually do anything"
          end

          puts "\n"

          uids = conn.imap.uid_search([ 'ALL' ]) if uids.nil?
          unless uids.nil? || uids.empty?
            puts "Found #{uids.size} e-mails"
            puts "  ** only working #{limit} at a time" if uids.size > limit
            puts "\n"

            marked = { }

            uids = uids.slice(0, limit)
            emails = conn.find_uids(uids).ok![0]
            emails.each do |email|
              at = email.received_time

              unless at.nil?
                if expire_at.nil? || at < expire_at
                  fp = figure_out_folder_path(email, filing)
                  fp_key = fp.join

                  if marked.include?(fp_key)
                    marked[fp_key].push(email)
                  else
                    marked[fp_key] = [ fp, email ]
                  end
                end
              else
                puts "  ! Skipping #{email.uid}, can't figure out received time"
              end
            end

            unless marked.empty?
              marked.each do |fp_key, marked_emails|
                fp = marked_emails.shift

                # let's first create the mailbox
                mb = conn.mk_mailbox_recursively(fp)
                puts "  Archiving to #{mb.name}"

                marked_uids = [ ]
                marked_emails.each do |email|
                  marked_uids.push(email.uid)
                  puts "    + #{email.display_line}"
                end

                puts "  ** Moving emails..."
                $stdout.flush

                unless dry_run
                  conn.copy(marked_uids, mb.name)

                  # now let's delete them!
                  conn.mark_deleted(marked_uids)
                  conn.expunge
                end

                puts "  !! Moved #{marked_uids.size} emails"
                $stdout.flush

                puts "\n"
              end
            else
              puts "  ** Nothing marked for archiving"
            end
          else
            puts "Found no e-mails"
          end
        end
      end

      def figure_out_folder_path(email, filing = :monthly)
        at = email.received_time

        case filing
        when :monthly
          fp = [ "%04d" % at.year, "%02d" % at.mon ]
        when :daily
          fp = [ "%04d" % at.year, "%02d" % at.mon, "%02d" % at.day ]
        else
          raise "Unsupported filing startegy #{filing}"
        end
      end
    end
  end
end


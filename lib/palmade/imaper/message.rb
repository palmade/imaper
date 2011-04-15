require 'time'

module Palmade::Imaper
  class Message
    Error.define_error(self, :MessageError, :message)

    attr_reader :header, :uid, :flags, :size

    def initialize(conn, params = { })
      @conn = conn
      @seqno = params[:seqno]
      @uid = params[:uid]
      @flags = params[:flags]
      @header = Mail::Header.new(params[:header])
      @size = params[:size]
    end

    def display_line
      from = @header[:from].addresses.first
      subject = @header[:subject].value
      subject = "%s..." % subject if subject.length > 40
      at = received_time

      if at.nil?
        at = '!'
      else
        at = at.to_s(:rfc2822)
      end

      sprintf("%s %s %s %s", uid, at, from, subject)
    end

    def received_time
      if defined?(@received_time)
        @received_time
      else
        at = nil
        @header[:received].each do |rcvd|
          at_txt = rcvd.value.split(/\s*\;\s*/, 2)[1]
          unless at_txt.nil? || at_txt.empty?
            at = Time.rfc2822(at_txt) rescue Time.prase(date) rescue nil
            unless at.nil?
              at = at.utc
              break
            end
          end
        end

        @received_time = at
      end
    end

    # retrieves the full e-mail message, from the IMAP server.
    #
    def fetch
      capture_errors(MessageError) do
        if defined?(@message) && !@message.nil?
          @message
        else
          Mail.new(conn.fetch(@uid).ok![0])
        end
      end
    end

    def mark_seen!
      capture_errors(MessageError) do
        conn.set_seen_flag(@uid)
      end
    end

    def mark_unseen!
      capture_errors(ImapMessageError) do
        conn.unset_seen_flag(@uid)
      end
    end

    def mark_parsed
      capture_errors(ImapMessageError) do
        conn.set_parsed_flag(@uid)
      end
    end

    def mark_unparsed!
      capture_errors(ImapMessageError) do
        conn.unset_parsed_flag(@uid)
      end
    end

    protected

    def conn
      unless @conn.disconnected?
        @conn
      else
        raise MessageError.new(:conn_disconnected)
      end
    end
  end
end

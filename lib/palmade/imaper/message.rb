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

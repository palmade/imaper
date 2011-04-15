require 'net/imap'

module Palmade::Imaper
  class Conn
    Error.define_error(self, :ConnError, :conn)

    def self.flags_klass=(c); @@flags_klass = c; end
    def self.flags_klass; @@flags_klass; end

    # set the default Flags class, override this
    # to use your own set of flags.
    self.flags_klass = Flags

    DEFAULT_MAILBOX = 'INBOX'.freeze

    DEFAULT_SETTINGS = {
      :mailbox => DEFAULT_MAILBOX,
      :address => 'localhost',
      :port => 143,
      :user_name => nil,
      :password => nil,
      :authentication => 'LOGIN',
      :ssl => false
    }

    attr_reader :settings

    def initialize(settings)
      @settings = DEFAULT_SETTINGS.merge(settings)
    end

    def imap
      if defined?(@imap) && !@imap.nil? && !@imap.disconnected?
        @imap
      else
        # connect
        @imap = Net::IMAP.new(@settings[:address],
                              :port => @settings[:port],
                              :ssl => @settings[:ssl] ? { :verify_mode => OpenSSL::SSL::VERIFY_NONE } : false)

        # authenticate
        @imap.authenticate(@settings[:authentication],
                           @settings[:user_name],
                           @settings[:password])

        # let's select the default mailbox
        select

        # return imap object
        @imap
      end
    end

    def find_unseen(limit = 10, &block)
      capture_errors(ConnError) do
        uids = find_unseen_uids
        unless uids.nil? || uids.empty?
          msgs = find_uids(working_uids = uids.slice(0, limit)).ok![0]

          if block_given?
            if block.arity == 2
              yield working_uids, msgs
            else
              yield headers
            end
          else
            [ working_uids, msgs ]
          end
        end
      end
    end

    def find_uids(*uids)
      capture_errors(ConnError) do
        [ fetch_headers(uids).ok![0].collect { |h| Message.new(self, h) } ]
      end
    end

    def fetch(*uids)
      capture_errors(ConnError) do
        resp = imap.uid_fetch(uids.flatten, [ "RFC822" ])
        unless resp.nil? || resp.empty?
          [ resp.collect { |r| r.attr['RFC822'] } ]
        else
          raise ConnError.new(:uid_fetch_returned_nil_or_empty)
        end
      end
    end

    def fetch_headers(*uids)
      capture_errors(ConnError) do
        resp = imap.uid_fetch(uids.flatten, [ "FLAGS", "RFC822.HEADER", "RFC822.SIZE" ])
        unless resp.nil? || resp.empty?
          [ resp.collect { |r|
              uid = r.attr['UID']

              unless uid.nil?
                { :seqno => r.seqno,
                  :uid => uid,
                  :flags => r.attr['FLAGS'],
                  :header => r.attr['RFC822.HEADER'],
                  :size => r.attr['RFC822.SIZE'].to_i
                }
              else
                nil
              end
            }.compact
          ]
        else
          raise ConnError.new(:uid_fetch_returned_nil_or_empty)
        end
      end
    end

    def find_unparsed_uids
      imap.uid_search([ 'UNKEYWORD', flags[:parsed] ])
    end

    def find_parsed_uids
      imap.uid_search([ 'KEYWORD', flags[:parsed] ])
    end

    def unset_parsed_flag(*uids)
      imap.uid_store(uids.flatten, '-FLAGS', [ flags[:parsed] ])
    end

    def set_parsed_flag(*uids)
      imap.uid_store(uids.flatten, '+FLAGS', [ flags[:parsed] ])
    end

    def find_unseen_uids
      imap.uid_search([ 'UNKEYWORD', flags[:seen] ])
    end

    def find_seen_uids
      imap.uid_search([ 'KEYWORD', flags[:seen] ])
    end

    def set_seen_flag(*uids)
      imap.uid_store(uids.flatten, '+FLAGS', [ flags[:seen] ])
    end

    def unset_seen_flag(*uids)
      imap.uid_store(uids.flatten, '-FLAGS', [ flags[:seen] ])
    end

    # just call imap method, as it will do a connection on demand.
    #
    def connect!
      imap
    end

    def disconnect!
      unless imap.nil?
        unless imap.disconnected?
          close
          imap.disconnect
        end
      end
    end

    def disconnected?
      unless imap.nil?
        imap.disconnected?
      else
        true
      end
    end

    def set_flags(f)
      @flags = f
    end

    def flags
      if defined?(@flags)
        @flags
      else
        self.class.flags_klass.new(self)
      end
    end

    protected

    def close
      imap.close
    end

    def select(mailbox = nil, &block)
      imap.select(mailbox || default_mailbox)
    end

    def default_mailbox
      @settings[:mailbox] || DEFAULT_MAILBOX
    end
  end
end

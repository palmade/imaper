require 'optparse'
require 'yaml'

module Palmade
  module Imaper
    class Cli
      attr_reader :config
      attr_reader :argv
      attr_reader :me_path

      def self.config_klass=(c); @@config_klass = c; end
      def self.config_klass; @@config_klass; end

      DEFAULT_DEBUG = true
      DEFAULT_LIST_COUNT = 10
      DEFAULT_ORDER = :desc

      # defaults to our own internal config class.
      self.config_klass = Palmade::Imaper::Config

      def self.run!(me_path, argv)
        new(me_path, argv).run!
      end

      def self.fail!(m)
        puts("FAIL: %s" % m)
        exit(-1)
      end

      def fail!(m)
        self.class.fail!(m)
      end

      def initialize(me_path, argv)
        @debugging = DEFAULT_DEBUG

        @me_path = me_path
        @argv = argv
      end

      def run!
        cmd_options = optsparse!(@argv)
        read_configuration!(cmd_options)
        sanitize_command_options!(cmd_options)

        # now, at this point, let's load other dependencies
        require_dependencies!

        case @argv[0]
        when 'list'
          Commands::ListCommand.new(self).run!(cmd_options)
        when 'mark', 'unmark'
          Commands::MarkCommand.new(self).run!(cmd_options)
        when 'archive'
          Commands::ArchiveCommand.new(self).run!(cmd_options)
        when 'auto_archive'
          Commands::AutoArchiveCommand.new(self).run!(cmd_options)
        when 'listmb'
          Commands::ListmbCommand.new(self).run!(cmd_options)
        when 'show'
          Commands::ShowCommand.new(self).run!(cmd_options)
        else
          puts @opts
        end
      rescue Exception => e
        if @debugging
          raise e
        else
          fail! "#{e.class.name} #{e.message}"
        end
      end

      protected

      def require_dependencies!
        require 'palmade/error_error'
        require 'mail'
      end

      def read_configuration!(cmd_options)
        options = { }

        if cmd_options.include?(:config_file)
          config_file = cmd_options[:config_file]
        else
          config_file = find_config_file_from_known_places
        end

        fail! "Unable to find config file, please specify one, or create one in known places" if config_file.nil?

        @config = self.class.config_klass.new
        @config.load_file!(config_file)

        options
      end

      def find_config_file_from_known_places
        found = nil

        [ 'config/imaper.yml',
          '~/.imaper.yml',
          '/opt/imaper/config/imaper.yml',
          '/etc/imaper.yml' ].each do |possible_location|
          if File.exists?(possible_location)
            found = possible_location
            break
          end
        end

        found
      end

      def sanitize_command_options!(cmd_options)
        if cmd_options.include?(:count)
          cmd_options[:count] = cmd_options[:count].to_i
        else
          cmd_options[:count] = DEFAULT_LIST_COUNT
        end

        if cmd_options.include?(:order)
          case cmd_options[:order]
          when 'desc'
            cmd_options[:order] = :desc
          when 'asc'
            cmd_options[:order] = :asc
          else
            fail! "Unsupported order #{cmd_options[:order]}"
          end
        else
          cmd_options[:order] = DEFAULT_ORDER
        end

        if cmd_options.include?(:start)
          cmd_options[:start] = cmd_options[:start].to_i
        else
          cmd_options[:start] = 0
        end

        unless cmd_options.include?(:dry_run)
          cmd_options[:dry_run] = false
        end

        cmd_options
      end

      def optsparse!(argv)
        cmd_options = { }

        @opts = OptionParser.new do |opts|
          opts.banner = "Usage: #{File.basename(@me_path)} [options] command *args"

          opts.on("-c", "--config [config_file]", "Read from configuration file") do |c|
            cmd_options[:config_file] = c
          end

          opts.on("-a", "--account [account_name]", "Select account") do |a|
            cmd_options[:account_name] = a
          end

          opts.on("--count [COUNT]", "Number of e-mails to show") do |count|
            cmd_options[:count] = count
          end

          opts.on("--order [ORDER]", "Order of e-mails to show") do |order|
            cmd_options[:order] = order
          end

          opts.on("--start [START]", "Start from a given offset in UID set") do |start|
            cmd_options[:start] = start
          end

          opts.on("--mailbox [mailbox_path]", "Use the specificied mailbox on the server") do |m|
            cmd_options[:mailbox_path] = m
          end

          opts.on("--dry-run", "Set to dry-run, don't do the real thing yet") do |dr|
            cmd_options[:dry_run] = true
          end
        end

        @opts.parse!(argv)

        cmd_options
      end
    end
  end
end

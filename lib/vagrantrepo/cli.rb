require 'logger'
require 'awesome_print'
require 'slop'
require 'vagrantrepo/field_option'
require 'vagrantrepo/slop_monkeypatches'


class String
  # Strips indentation in heredocs.
  #
  # For example in
  #
  #   if options[:usage]
  #     puts <<-USAGE.strip_heredoc
  #       This command does such and such.
  #
  #       Supported options are:
  #         -h         This message
  #         ...
  #     USAGE
  #   end
  #
  # the user would see the usage message aligned against the left margin.
  #
  # Technically, it looks for the least indented non-empty line
  # in the whole string, and removes that amount of leading whitespace.
  def strip_heredoc
    gsub(/^#{scan(/^[ \t]*(?=\S)/).min}/, ''.freeze)
  end
end

module Vagrantrepo
  # cli helpers
  module CLI
    def self.logger

      AwesomePrint.defaults = {
        raw: true,
        indent: 2,
      }

      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO
      # +severity+:: The Severity of the log message.
      # +time+:: A Time instance representing when the message was logged.
      # +progname+:: The #progname configured, or passed to the logger method.
      # +msg+::
      logger.formatter = proc { |severity, time, _progname, msg|
        format "%<time>s %<severity>s: %<message>s\n",
               severity: severity,
               message: msg.to_s,
               time: time
      }
      logger
    end

    def self.options(logger)
      Slop.parse do |o|
        o.separator 'Box scanner'
        o.string '--root', 'Repository root directory',
                 default: Vagrantrepo::Collect::DEFAULT_ROOT
        o.string '--filter', 'Additional file filter to use.',
                 default: Vagrantrepo::Collect::DEFAULT_FILTER
        o.string '--meta-template', 'Naming template for the vagrant meta files.',
                 default: Vagrantrepo::Collect::DEFAULT_META_TEMPLATE
        o.separator ''
        o.separator 'Output options'
        o.string '--output', 'Output root for updates meta files',
                 default: Vagrantrepo::Updater::DEFAULT_OUTPUT_PATH
        o.string '--output-meta-template', 'Naming template for the updated vagrant meta files',
                 default: Vagrantrepo::Updater::DEFAULT_META_TEMPLATE
        o.field '--meta-field', 'overwrite a field for the boxes.'
        o.bool '--purge', <<-DESCRIPTION.strip_heredoc
            Remove all box versions that are no longer on the filesystem.

            You should enable this when you run the tool on the webserver
            where all boxes are hosted. If you use this to only add a single
            new box on your ci server and update the config that way, disable this.
          DESCRIPTION
        o.string '--vendor', 'Vendor used in metadata box name.', required: true
        o.string '--url', 'Url repository root.', required: true
        o.separator ''
        o.separator 'Global options'
        o.on '-q', '--quiet', 'only warnings and errors are printed.' do
          logger.level = logger.level == Logger::DEBUG ? Logger::DEBUG : Logger::WARN
        end
        o.on '-d', '--debug', 'debug logging. takes precedence over silent.', help: false do
          logger.level = Logger::DEBUG
        end
        o.on '--version', 'print the version' do
          puts Vagrantrepo::VERSION
          exit
        end
        o.on '--help' do
          puts o
          exit
        end
      end
    end
  end
end

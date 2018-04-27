require 'logger'
require 'awesome_print'
require 'slop'

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

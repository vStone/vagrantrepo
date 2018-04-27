require 'logger'
require 'awesome_print'

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
  end
end

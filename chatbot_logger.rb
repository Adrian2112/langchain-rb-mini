require 'logger'

class ChatbotLogger
  COLORS = {
    :red => 31,
    :green => 32,
    :yellow => 33,
    :blue => 34,
    :pink => 35,
    :light_blue => 36
  }

  def initialize(logdev = STDOUT)
    @logger = Logger.new(logdev)
    @logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }
  end

  def colorize(color, text)
    "\e[#{COLORS[color]}m#{text}\e[0m"
  end

  def info(msg)
    @logger.info(msg)
  end

  def warn(msg)
    @logger.warn(msg)
  end

  def error(msg)
    @logger.error(msg)
  end
end

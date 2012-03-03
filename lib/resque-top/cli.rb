require 'resque'

module Resque::Top
  class CLI
    def initialize(options)
      if options[:redis]
        Resque.redis = options[:redis]
      end
      if options[:namespace]
        Resque.redis.namespace = options[:namespace]
      end

      @width, @height = detect_terminal_size
    end

    def run
      loop do
        display
        sleep 1
      end
    rescue Interrupt
    end

    def right_float(target, str)
      target << (' ' * (@width - target.length - str.length)) + str
    end

    def display
      out = []
      out << "Resque connected to: #{Resque.redis_id} (#{Resque.redis.namespace})"
      out << ""

      out << "Queues: "
      Resque.queues.each do |queue|
        out << "  #{queue} | #{Resque.size(queue)}"
      end
      out << "  failed | #{Resque::Failure.count}"
      out << ""

      out << "Workers:"
      workers = Resque.workers.sort_by { |w| w.to_s }

      workers.each do |worker|
        line = ''
        host, pid, queues = worker.to_s.split(':')
        line << "  #{host}:#{pid} | #{queues} | "
        data = worker.processing || {}
        if data['queue']
          line << "#{data['payload']['class']} (#{data['run_at']})"
        else
          line << "Waiting for a job...."
        end
        out << line
      end

      if workers.empty?
        out << "There are no registered workers"
      end

      (@height - out.size - 2).times do out << "" end
      out << "(Ctrl-c to quit.)"

      right_float(out[0], Time.now.strftime('%H:%M:%S'))

      clear
      puts out.join("\n")
    end

    def clear
      print "\033[2J"
    end

    def command_exists?(command)
      ENV['PATH'].split(File::PATH_SEPARATOR).any? { |d| File.exists? File.join(d, command) }
    end

    # https://github.com/cldwalker/hirb/blob/master/lib/hirb/util.rb#L61-71
    def detect_terminal_size
      if (ENV['COLUMNS'] =~ /^\d+$/) && (ENV['LINES'] =~ /^\d+$/)
        [ENV['COLUMNS'].to_i, ENV['LINES'].to_i]
      elsif (RUBY_PLATFORM =~ /java/ || (!STDIN.tty? && ENV['TERM'])) && command_exists?('tput')
        [`tput cols`.to_i, `tput lines`.to_i]
      elsif STDIN.tty? && command_exists?('stty')
        `stty size`.scan(/\d+/).map {  |s| s.to_i }.reverse
      else
        nil
      end
    rescue Exception => e
      nil
    end
  end
end

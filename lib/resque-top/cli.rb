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

    def tabular(rows, indent=2, separator="|")
      if rows.empty?
        nil
      else
        longest = [0] * rows[0].count
        rows.each do |cols|
          cols.each_with_index do |value, i|
            longest[i] = [ longest[i], value.to_s.length ].max
          end
        end
        rows.collect do |row|
          longest.each_with_index do |value, i|
            row[i] = justify(value, row[i])
          end
          (" " * indent) + row.join(" | ")
        end
      end
    end

    def justify(longest, string)
      if string.is_a?(Integer)
        string.to_s.rjust(longest)
      else
        string.ljust(longest)
      end
    end

    def display
      out = []
      out << "Resque connected to: #{Resque.redis_id} (#{Resque.redis.namespace})"
      out << ""

      out << "Queues: "
      rows = []
      Resque.queues.each do |queue|
        rows << [ queue, Resque.size(queue) ]
      end
      rows << [ "failed", Resque::Failure.count ]
      out.push *(tabular(rows))

      out << ""

      out << "Workers:"
      workers = Resque.workers.sort_by { |w| w.to_s }

      workers.each do |worker|
        line = ''
        host, pid, queues = worker.to_s.split(':')
        cols = []
        cols << [ "#{host}:#{pid}", queues ]
        data = worker.processing || {}
        if data['queue']
          cols[-1].push "#{data['payload']['class']} (#{data['run_at']})"
        else
          cols[-1].push "Waiting for a job...."
        end
        out.push *(tabular(cols))
      end

      if workers.empty?
        out << "  (There are no registered workers)"
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

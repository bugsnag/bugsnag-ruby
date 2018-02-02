require 'open3'

$compose_stacks ||= Set.new

def current_ip
  `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\\\.){3}[0-9]*' | grep -Eo '([0-9]*\\\.){3}[0-9]*' | grep -v '127.0.0.1'`.strip
end

def run_command(cmd, print_output: false)
  Open3.popen3(cmd) do |stdin, stdout, stderr, thread|
    { :out => stdout, :err => stderr }.each do |key, stream|
      Thread.new do
        until (output = stream.gets).nil? do
          STDOUT.puts output if print_output
        end
      end
    end

    thread.join
  end
end

at_exit do
  $compose_stacks.each { |filename| run_command "docker-compose -f #{filename} down" }
end

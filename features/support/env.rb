require 'open3'

Before do
  find_default_docker_compose
end

def output_logs
  $docker_services.each do |service|
    logged_service = service[:service] == :all ? '' : service[:service]
    command = "logs -t #{logged_service}"
    begin
      response = run_docker_compose_command(service[:file], command)
    rescue => exception
      response = "Couldn't retreive logs for #{service[:file]}:#{logged_service}"
    end
    STDOUT.puts response.is_a?(String) ? response : response.to_a
  end
end

def current_ip
  # Parses the output of `ifconfig` to retreive the host IP for docker to talk to
  # Breaks compatability with Windows
  ip_addr = `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\\\.){3}[0-9]*' | grep -v '127.0.0.1'`
  ip_list = /((?:[0-9]*\.){3}[0-9]*)/.match(ip_addr)
  ip_list.captures.first
end

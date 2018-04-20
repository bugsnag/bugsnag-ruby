require 'open3'

def setup_default_environment
  ENV['RAILS_3_PORT'] = '3000'
  ENV['RAILS_4_PORT'] = '3000'
  ENV['RAILS_5_PORT'] = '3000'
end

def current_ip
  # Parses the output of `ifconfig` to retreive the host IP for docker to talk to
  # Breaks compatability with Windows
  ip_addr = `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\\\.){3}[0-9]*' | grep -v '127.0.0.1'`
  ip_list = /((?:[0-9]*\.){3}[0-9]*)/.match(ip_addr)
  ip_list.captures.first
end

setup_default_environment

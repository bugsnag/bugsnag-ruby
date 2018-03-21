require 'open3'

def current_ip
  `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\\\.){3}[0-9]*' | grep -Eo '([0-9]*\\\.){3}[0-9]*' | grep -v '127.0.0.1'`.strip
end
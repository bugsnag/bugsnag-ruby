require 'open3'
require 'pp'

def current_ip
  ip_addr = `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\\\.){3}[0-9]*' | grep -v '127.0.0.1' | awk '{ print $2 }'`.strip
  pp ip_addr
  ip_addr
end
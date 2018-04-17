require 'open3'
require 'pp'

def current_ip
  ip_addr = `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\\\.){3}[0-9]*' | grep -v '127.0.0.1'`
  pp ip_addr
  ip_list = /(([0-9]*\.){3}[0-9]*)/.match(ip_addr)
  pp ip_list
  pp ip_list.captures.first
  ip_list.captures.first
end
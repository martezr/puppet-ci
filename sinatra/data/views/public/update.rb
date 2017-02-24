#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"

conn = Bunny.new(:hostname => "192.168.1.229")
conn.start

ch   = conn.create_channel
q    = ch.queue("jjb")
ch.default_exchange.publish("Update Jenkins", :routing_key => q.name)
puts " [x] Sent 'Update Jenkins'"
conn.close

#!/usr/bin/env ruby
# encoding: utf-8

require 'bunny'
require 'xmlsimple'

@rabbitmq_server = 'rabbitmq'

def updateconfig
  address = ENV["CONTAINER_HOST"]
  config = XmlSimple.xml_in('config.xml', { 'KeyAttr' => 'name' })
  config['clouds'][0]['com.nirima.jenkins.plugins.docker.DockerCloud'][0]['serverUrl'] = ["tcp://#{address}:2375"]
  output = XmlSimple.xml_out(config, { "RootName" => "hudson" })

  File.write('config.xml', output)
end

begin
  retries ||= 0
  puts 'sleeping for 30 seconds while rabbitmq boots'
  sleep 30
  conn = Bunny.new(:hostname => @rabbitmq_server)
  conn.start
rescue Bunny::TCPConnectionFailed => e
  puts "Connection to @rabbitmq_server failed"
  retry if (retries += 1) < 3  
end

ch = conn.create_channel
q  = ch.queue("jenkinsconfig")

puts " [*] Waiting for messages in #{q.name}."
q.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
  `echo "[x] Received #{body}" >> /var/log/jenkinsconfig.log` 
  updateconfig()

  ch.ack(delivery_info.delivery_tag)
end

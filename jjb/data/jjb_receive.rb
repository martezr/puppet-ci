#!/usr/bin/env ruby
# encoding: utf-8

require 'bunny'
require 'etcd'
require 'json'
require 'yaml'


@rabbitmq_server = 'rabbitmq'
@etcd_server = 'etcd'
@etcd_port = '4001'

# Retrieve data from ETCD
def queryetcd
  client = Etcd.client(host: @etcd_server, port: @etcd_port)
  @controlrepo = client.get('/configuration/controlrepo').value
  @jenkins_url = client.get('/configuration/jenkins_url').value
  @jenkins_username = client.get('/configuration/jenkins_username').value
  @jenkins_password = client.get('/configuration/jenkins_password').value
end

# Update JJB Control Repo Job
def updatejob
  data = YAML.load(File.open('controlrepo.yaml'))
  data[0]['job']['scm'][0]['git']['url'] = @controlrepo

  File.open("controlrepo.yaml", 'w') { |f| YAML.dump(data, f) }
end

def updateconfig
  jjbconfig = File.open("jenkins_job.ini", "w:UTF-8")
  jjbconfig.puts "[job_builder]"
  jjbconfig.puts "ignore_cache=True"
  jjbconfig.puts "keep_descriptions=False"
  jjbconfig.puts "allow_duplicates=False"
  jjbconfig.puts "\n"

  jjbconfig.puts "[jenkins]"
  jjbconfig.puts "user=#@jenkins_username"
  jjbconfig.puts "password=#@jenkins_password"
  jjbconfig.puts "url=#@jenkins_url"
  jjbconfig.puts "query_plugins_info=False"
  jjbconfig.close
end


conn = Bunny.new(:hostname => @rabbitmq_server)
conn.start

ch   = conn.create_channel
q    = ch.queue("jjb")

puts " [*] Waiting for messages in #{q.name}."
q.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
  `echo "[x] Received #{body}" >> /var/log/jjb.log` 
  queryetcd()
  updatejob()
  updateconfig()
  `jenkins-jobs --conf jenkins_job.ini update controlrepo.yaml`

  ch.ack(delivery_info.delivery_tag)
end

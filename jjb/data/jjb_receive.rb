#!/usr/bin/env ruby
# encoding: utf-8

require 'bunny'
require 'etcd'
require 'json'
require 'yaml'
require 'net/http'
require 'uri'

@rabbitmq_server = 'rabbitmq'
@etcd_server = 'etcd'
@etcd_port = '4001'
@jenkins_server = 'jenkins'

# Add Docker Jenkins Credentials
def adddockerjenkinscreds

  uri = URI.parse("http://#@jenkins_server:8080/credentials/store/system/domain/_/createCredentials")
  request = Net::HTTP::Post.new(uri)
  request.body = "json={  
    \"\": \"0\",
    \"credentials\": {
      \"scope\": \"GLOBAL\",
      \"id\": \"dockerjenkins\",
      \"username\": \"jenkins\",
      \"password\": \"jenkins\",
      \"description\": \"apicredentials\",
      \"stapler-class\": \"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\"
    }
  }"

  req_options = {
    use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  puts "Added Docker credentials to Jenkins"

end



# Retrieve data from ETCD
def queryetcd
  client = Etcd.client(host: @etcd_server, port: @etcd_port)
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


def updatejenkinssettings
  client = Etcd.client(host: @etcd_server, port: @etcd_port)
  @jenkins_url = client.get('/configuration/jenkins_url').value
  @jenkins_username = client.get('/configuration/jenkins_username').value
  @jenkins_password = client.get('/configuration/jenkins_password').value
  @jenkins_sshkey = client.get('/configuration/jenkins_sshkey').value
  
  updateconfig()
end

begin
  retries ||= 0
  puts 'sleeping for 15 seconds while rabbitmq boots'
  sleep 15
  conn = Bunny.new(:hostname => @rabbitmq_server)
  conn.start
rescue Bunny::TCPConnectionFailed => e
  puts "Connection to @rabbitmq_server failed"
  retry if (retries += 1) < 3  
end

ch   = conn.create_channel
q    = ch.queue("jjb")

puts " [*] Waiting for messages in #{q.name}."
q.subscribe(:manual_ack => true, :block => true) do |delivery_info, properties, body|
  `echo "[x] Received #{body}" >> /var/log/jjb.log` 
  updatejenkinssettings()
  adddockerjenkinscreds()
  `jenkins-jobs --conf jenkins_job.ini update controlrepo.yaml`

  ch.ack(delivery_info.delivery_tag)
end

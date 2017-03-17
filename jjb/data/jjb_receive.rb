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
      \"description\": \"Docker Credentials\",
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

# Add Jenkins SSH Key Credentials
def addjenkinssshcredentials
  client = Etcd.client(host: 'etcd', port: '4001')
  jenkins_sshkey = client.get('/configuration/jenkins_sshkey').value

  uri = URI.parse("http://#@jenkins_server:8080/credentials/store/system/domain/_/createCredentials")
  request = Net::HTTP::Post.new(uri)
  request.body = "json={  
    \"\": \"0\",
    \"credentials\": {
      \"scope\": \"GLOBAL\",
      \"id\": \"jenkinsssh\",
      \"username\": \"jenkinsssh\",
      \"password\": \"\",
      \"privateKeySource\": {
        \"stapler-class\": \"com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey$DirectEntryPrivateKeySource\",
        \"privateKey\": \"#{jenkins_sshkey}\",
      },
      \"description\": \"Puppet Repo Credentials\",
      \"stapler-class\": \"com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\"
    }
  }"

  req_options = {
    use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  puts response.code
  puts response.body

  puts "Add Jenkins SSH Key credentials to Jenkins"
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
  client = Etcd.client(host: 'etcd', port: '4001')
  @controlrepo = client.get('/configuration/puppetcontrolrepourl').value
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

def addpuppetmodule
  uri = URI.parse("http://etcd:2379/v2/keys/configuration/modules")
  response = Net::HTTP.get_response(uri)

  result = response.body

  parsed = JSON.parse(result)
  modules = parsed['node']['nodes']

  modulejobs = File.open("./modules/puppetmodules.yaml", "w")
  modulejobs.puts "- project:"
  modulejobs.puts "    name: puppet-modules"
  modulejobs.puts "    jobs:"

  for puppetmodule in modules
    modulepath = puppetmodule['key']
    uribase = "http://etcd:2379/v2/keys" + modulepath
    uri = URI.parse("#{uribase}")
    response = Net::HTTP.get_response(uri)
    result = response.body
    parsed = JSON.parse(result)
    keys = parsed['node']['nodes']
    for key in keys
      teststring = key['key']
      if teststring.include? "name"
        @name = key['value']
      elsif teststring.include? "branch"
        @branch = key['value']
      elsif teststring.include? "url"
        @url = key['value']
      end
    end
    modulejobs.puts '      - puppet-module-{name}:'
    modulejobs.puts "         name: #@name"
    modulejobs.puts "         url: #@url"
    modulejobs.puts "         branch: #@branch"      
  end
  modulejobs.close
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
  
  # Conditional logic to determine action taken
  case body
  when "Update Jenkins"
    updatejenkinssettings()
    adddockerjenkinscreds()
    addjenkinssshcredentials()
  when "Update Puppet"
    updatejob()
    `jenkins-jobs --conf jenkins_job.ini update controlrepo.yaml`
  when "Add Puppet Module"
    addpuppetmodule()
    `jenkins-jobs --conf jenkins_job.ini update ./modules/`
  end    

  ch.ack(delivery_info.delivery_tag)
end

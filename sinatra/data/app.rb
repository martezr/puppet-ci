require 'sinatra'
require 'json'
require 'etcd'
require 'bunny'

set :bind, '0.0.0.0'
set :port, 80

set :public_folder, 'public'
set :views, 'views'

@rabbitmq_server = 'rabbitmq'
@etcd_server = 'etcd'
@etcd_port = '4001'

get '/' do
  File.read(File.join('public', 'index.html'))
end

get '/systemsettings' do
  File.read(File.join('public', 'systemsettings.html'))
end

get '/jenkinssettings' do
  File.read(File.join('public', 'jenkinssettings.html'))
end

post '/jenkinssettings' do
  params.to_s
  jenkins_url = params['jenkins_url']
  jenkins_username = params['jenkins_username']
  jenkins_password = params['jenkins_password']
  jenkins_sshkey = params['jenkins_sshkey']
  # Strip carriage returns added by the text area form
  jenkins_sshkey = jenkins_sshkey.gsub(/\r\n/,'')

  @client = Etcd.client(host: "etcd", port: "4001")

  if jenkins_url.nil?
    @client.set('/configuration/jenkins_url', value: "http://jenkins:8080")
  else
    @client.set('/configuration/jenkins_url', value: "#{'jenkins_url'}")
  end

  if jenkins_username.nil?
    @client.set('/configuration/jenkins_username', value: "jenkins")
  else
    @client.set('/configuration/jenkins_username', value: "#{'jenkins_username'}")
  end

  if jenkins_password.nil?
    @client.set('/configuration/jenkins_password', value: "jenkins")
  else
    @client.set('/configuration/jenkins_password', value: "#{'jenkins_password'}")
  end

  if jenkins_sshkey.nil?
    `echo "jenkins_sshkey is empty" >> /var/log/app.log`
  else
    @client.set('/configuration/jenkins_sshkey', value: "#{jenkins_sshkey}")
  end

  conn = Bunny.new(:hostname => 'rabbitmq')
  conn.start

  ch   = conn.create_channel
  q    = ch.queue("jjb")
  ch.default_exchange.publish("Update Jenkins", :routing_key => q.name)
  puts " [x] Sent 'Update Jenkins Settings'"
  conn.close
end

post '/puppetsettings' do
  params.to_s
  repo_url = params['puppetcontrolrepourl']

  @client = Etcd.client(host: "etcd", port: "4001")
  @client.set('/configuration/puppetcontrolrepourl', value: "#{repo_url}")

  conn = Bunny.new(:hostname => 'rabbitmq')
  conn.start

  ch   = conn.create_channel
  q    = ch.queue("jjb")
  ch.default_exchange.publish("Update Puppet", :routing_key => q.name)
  puts " [x] Sent 'Update Puppet Settings'"
  conn.close
end

post '/update' do
  `ruby public/update.rb`
end

get '/controlrepo' do
    content_type :json
    File.read('public/spells.json')
end

require 'sinatra'
require 'json'
require 'etcd'
require 'bunny'

set :bind, '0.0.0.0'


set :public_folder, 'public'
set :views, 'views'

@rabbitmq_server = 'rabbitmq'
@etcd_server = 'etcd'
@etcd_port = '4001'



get '/' do
  erb :home
end


get '/configuration' do
  erb :configure
end

post '/jenkinssettings' do
  client = Etcd.client(host: @etcd_server, port: @etcd_port)
  client.set('/configuration/jenkins_url', value: "#{params['jenkins_url']}")
  client.set('/configuration/jenkins_username', value: "#{params['jenkins_username']}")
  client.set('/configuration/jenkins_password', value: "#{params['jenkins_password']}")
  client.set('/configuration/jenkins_sshkey', value: "#{params['jenkins_sshkey']}")


  conn = Bunny.new(:hostname => @rabbitmq_server)
  conn.start

  ch   = conn.create_channel
  q    = ch.queue("jjb")
  ch.default_exchange.publish("Update Jenkins", :routing_key => jenkinssettings)
  puts " [x] Sent 'Update Jenkins Settings'"
  conn.close
end

post '/puppetsettings' do
  params.to_s
  tempHash = {
    "Server" => "#{params['controlrepo']}",
  }
  File.open("public/spells.json","w") do |f|
    f.write(tempHash.to_json)
  end
end

post '/update' do
  `ruby public/update.rb`
end

get '/controlrepo' do
    content_type :json
    File.read('public/spells.json')
end

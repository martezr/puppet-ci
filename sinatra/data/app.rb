require 'sinatra'
require 'json'
require 'etcd'


set :bind, '0.0.0.0'


set :public_folder, 'public'
set :views, 'views'

get '/' do
  erb :home
end


get '/configuration' do
  erb :configure
end

post '/configuration' do
  params.to_s
  tempHash = {
    "Server" => "#{params['controlrepo']}",
  }
  File.open("public/spells.json","w") do |f|
    f.write(tempHash.to_json)
  end
  client = Etcd.client(host: '192.168.1.229', port: 4001)
  client.set('/configuration/controlrepo', value: "#{params['controlrepo']}")
  client.set('/configuration/jenkins_url', value: "#{params['jenkins_url']}")
  client.set('/configuration/jenkins_username', value: "#{params['jenkins_username']}")
  client.set('/configuration/jenkins_password', value: "#{params['jenkins_password']}")

  status, headers, body = call env.merge("PATH_INFO" => '/update')
  [status, headers, body.map(&:upcase)]
end

post '/update' do
  `ruby public/update.rb`
end

get '/controlrepo' do
    content_type :json
    File.read('public/spells.json')
end

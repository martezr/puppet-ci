require 'sinatra'
require 'json'
require 'etcd'
require 'bunny'

set :bind, '0.0.0.0'
set :port, 8000

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

get '/puppetmodules' do

  def jsonoutput(name,url,branch)
    tempHash = {
      "name" => name,
      "url" => url,
      "branch" => branch
    }
    return tempHash.to_json
  end


  uri = URI.parse("http://etcd:2379/v2/keys/configuration/modules")
  response = Net::HTTP.get_response(uri)

  result = response.body

  parsed = JSON.parse(result)
  modules = parsed['node']['nodes']

  @output = []

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
    @output << jsonoutput(@name,@url,@branch)
  end

  finaloutput = JSON.pretty_generate(@output).gsub('\\', '').gsub('}"', '}').gsub('"{', '{')

  open('test.json', 'w') { |f|
    f.puts(finaloutput)
  }
  
  content_type :json
  File.read('test.json')

end

post '/addpuppetmodule' do

  # Check if key exists and retrieve value
  client = Etcd.client(host: 'etcd', port: '4001')
  test_key = client.exists?('/configuration/module_number')

  if test_key
    module_number = client.get('/configuration/module_number').value
  else
    module_number = '0'
  end

  params.to_s
  module_name = params['puppet_module_name']
  module_url = params['puppet_module_url']
  module_branch = params['puppet_module_branch']

  # Increment previous etcd value
  module_number = module_number.to_i
  module_number += 1
  module_number = module_number.to_s
  client.set('/configuration/module_number', value: "#{module_number}")

  client.set("/configuration/modules/module#{module_number}/name", value: "#{module_name}")
  client.set("/configuration/modules/module#{module_number}/url", value: "#{module_url}")
  client.set("/configuration/modules/module#{module_number}/branch", value: "#{module_branch}")

  conn = Bunny.new(:hostname => 'rabbitmq')
  conn.start

  ch   = conn.create_channel
  q    = ch.queue("jjb")
  ch.default_exchange.publish("Add Puppet Module", :routing_key => q.name)
  puts " [x] Sent 'Added Puppet Module'"
  conn.close

end

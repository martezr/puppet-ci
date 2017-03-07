# puppetci

The intent of this project is to build out a turnkey appliance that can be deployed into an environment and provide continuous integration for Puppet. The appliance will utilize various open source technologies to provide a robust solution that can be easily scaled as needed.

##Architecture
The solution ties together various technologies as seen in the architecture diagram below.

![](http://www.greenreedtech.com/content/images/2017/02/PuppetCI_Architecture.png)

| container | function                      | cpu limit | ram limit | exposed ports                  |
|-----------|-------------------------------|-----------|-----------|--------------------------------|
| sinatra   | web interface                 | 0.5       | 25M       | 80                             |
| etcd      | key value store               | 0.5       | 25M       | 4001                           |
| rabbitmq  | message queue                 | 0.5       | 100M      | 15672, 5671, 5672, 4369, 25672 |
| jenkins   | continuous integration server | 0.5       | 800M      | 8080, 50000                    |
| jjb       | jenkins job builder container | 0.25      | 25M       | n/a                            |

**Docker**   
Docker will provide the base environment for the other services to run on. Docker provides excellent portability and scalability to the solution as it can expand to additional nodes without a major rework of the solution.

**Sinatra**  
Sinatra will present the Web UI and act as the API endpoint for the solution.

**RabbitMQ**  
RabbitMQ is the glue that connects everything. In the interest of creating an easily scalable distributed system all task requests are sent through the RabbitMQ server and picked up by the appropriate executor.

**Jenkins Job Builder**  
Jenkins Job Builder is utilized to dynamically create the Jenkins jobs on the Jenkins master.
 
**Jenkins**  
Jenkins is the core component that provides the continuous integration framework for validating and testing our code.

**ELK**  
ELK will provide visualization of data from the Puppet CI jobs with metrics such as rspec results, serverspec results, provisioning time, etc. ELK also provides a mechanism for collecting and visualizing data about the environment for things such as health metrics and container logging. 

**Test Kitchen**  
Test kitchen will be used to provide a robust harness for acceptance and integration testing on configured systems.

**Vagrant**  
Vagrant provides the provisioner utilized by Test Kitchen for spinning up machines locally in VirtualBox.

**VirtualBox**
VirtualBox provides the virtualization layer for Vagrant to provision test machines.

####Additional Technologies
Consideration has been given to adding the following technologies to the solution to provide additional functionality.

* Nexus: Artifact Management  
* Geminabox: Gem repository

## Roadmap

Release 0.0.1
* ~~Update readme.md~~
* ~~Add roadmap~~
* Clean up code
* ~~Add Jenkins slave images~~
* Add temporary home dashboard
* ~~Rework configuration page~~
* Add API action to trigger Jenkins jobs

Release 0.0.2
* Add CA
* Add hashicorp vault for secrets encryption
* Add etcd cluster
* Add notification settings
* Docker host hardening
* Build home dashboard
* Add module jobs
* Validate rspec testing
* Add SSH key textbox
* Create environment health checks

Release 0.0.3
* Configure environment logging
* Add test kitchen support
* Add test kitchen containers
* Add test kitchen docker support
* ~~Begin UI migration to AngularJS~~

Release 0.0.4
* Add serverspec support
* Add virtualbox
* Add vagrant
* Add test kitchen vagrant support

Release 0.0.5
* Add authentication
* Add SSO
* Add configuration backup

#!/bin/bash

yum -y install epel-release

# Install Ansible
yum -y install git ansible libselinux-python

# Clone puppet-ci github repository
rm -Rf puppet-ci
git clone https://github.com/martezr/puppet-ci.git
cd puppet-ci

rm -Rf /etc/ansible
cp -R ansible/ /etc/
setenforce 0


# Set docker host 
CONTAINER_HOST=$(ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+')
sed -i "s#tcp://:2375#tcp://$CONTAINER_HOST:2375#" jenkins/config.xml

ansible-playbook /etc/ansible/install.yml && docker-compose up -d
cd docker-jenkins-slave
sh build.sh

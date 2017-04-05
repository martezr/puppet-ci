#!/bin/bash

yum -y install epel-release

# Install Ansible
yum -y install git ansible libselinux-python

cd puppet-ci
rm -Rf /etc/ansible
cp -R ansible/ /etc/
setenforce 0

# Install Docker
time ansible-playbook /etc/ansible/install.yml

# Set docker host 
CONTAINER_HOST=$(ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+')
sed -i "s#tcp://:2375#tcp://$CONTAINER_HOST:2375#" jenkins/config.xml

time docker-compose up -d
cd docker-jenkins-slave
time sh build.sh

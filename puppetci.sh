#!/bin/bash

yum -y install epel-release

# Install Ansible
yum -y install git ansible libselinux-python

rm -Rf /etc/ansible
cp -R ansible/ /etc/
setenforce 0

# Install Docker
ansible-playbook /etc/ansible/install.yml

# Set docker host 
CONTAINER_HOST=$(ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+')
sed -i "s#tcp://:2375#tcp://$CONTAINER_HOST:2375#" jenkins/config.xml

docker-compose up -d
cd docker-jenkins-slave
sh build.sh

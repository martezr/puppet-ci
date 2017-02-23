#!/bin/bash

# This script is used to install RVM as the jenkins user for the CI environment

# Add the gpg key to the system
su - jenkins -c "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3"

# Install rvm
su - jenkins -c "\curl -sSL https://get.rvm.io | bash -s stable"

# Utilize the latest version of CentOS as the base
FROM centos:7

# Define the maintainer
MAINTAINER Martez Reed "martez.reed@greenreedtech.com"

# Update system
RUN yum -y update && yum -y upgrade && yum clean all

# Install ansible, openssh-server and supervisor
RUN yum -y install epel-release && yum -y install ansible openssh-server supervisor

# Copy Ansible roles into container
COPY ansible-roles /etc/ansible/roles/ansible-roles

# Define container role
ARG ROLE

# Assign container role
RUN echo "[$ROLE]" > /etc/ansible/hosts && echo "localhost" >> /etc/ansible/hosts && ls /etc/ansible/roles

# Run ansible playbook
RUN ansible-playbook -c local /etc/ansible/roles/ansible-roles/site.yml

RUN echo "root:password" | chpasswd

# Create jenkins user and set password
RUN echo "jenkins:jenkins" | chpasswd

# Create /var/run/sshd and /var/run/supervisord directory and create ssh keys
RUN mkdir -p /var/run/sshd && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' && mkdir -p /var/run/supervisord

# Modify ssh login configuration
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd  

# Add supervisord.conf configuration file to the container
ADD supervisord.conf /etc/supervisord.conf  
  
# Expose port 22 for SSH access
EXPOSE 22

# Start the SSHD service on container start
CMD ["/usr/bin/supervisord"]  

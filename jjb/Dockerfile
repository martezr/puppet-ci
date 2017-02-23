FROM centos:7
ENV VERSION 1.4.0
RUN yum -y install epel-release
RUN yum -y install rubygems python-setuptools python-dev libyaml-dev git curl python-pip python-yaml
RUN pip install pbr PyYAML python-jenkins jenkins-job-builder
RUN mkdir /opt/puppetci
COPY data /opt/puppetci
WORKDIR /opt/puppetci
RUN gem install bundler && bundle install
CMD ["/opt/puppetci/jjb_receive.rb"]

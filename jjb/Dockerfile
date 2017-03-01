FROM centos:7
RUN yum -y install epel-release && yum -y install rubygems python-setuptools python-devel libyaml-devel git curl python-pip python-yaml
RUN pip install pbr==1.10.0 PyYAML python-jenkins jenkins-job-builder
RUN mkdir /opt/puppetci
COPY data /opt/puppetci
WORKDIR /opt/puppetci
RUN gem install bundler && bundle install
CMD ["/opt/puppetci/jjb_receive.rb"]

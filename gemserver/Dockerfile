# Centos:7 base image
FROM centos:7

# Install rubygems and geminabox gem
RUN yum -y install rubygems && gem install geminabox

# Copy config.ru rack config file to container
COPY config.ru /

# Create gem repo
RUN mkdir /gemrepo

# Expose port 9292 to host
EXPOSE 9292

# Start geminabox server
ENTRYPOINT ["rackup", "--host", "0.0.0.0"]

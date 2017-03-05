FROM centos:7

ENV PATH /home/sinatra/bin:$PATH
ENV APP_ROOT /home/sinatra

RUN groupadd sinatra && useradd -m -g sinatra sinatra
RUN yum -y install rubygems
USER sinatra
RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT
COPY Gemfile* $APP_ROOT/
COPY data/ $APP_ROOT/
RUN gem install bundler && bundle install

# Start server
EXPOSE 8000
CMD ["ruby", "/home/sinatra/app.rb"]


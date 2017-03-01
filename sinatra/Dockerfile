FROM centos:7

RUN yum -y install rubygems
ENV APP_ROOT /usr/src/app
RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT
COPY Gemfile* $APP_HOME/
COPY data/ $APP_ROOT/
RUN gem install bundler && bundle install

# Start server
ENV PORT 80
EXPOSE 80
CMD ["ruby", "/usr/src/app/app.rb"]

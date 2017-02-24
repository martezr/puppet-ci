FROM ruby:2.3.1-slim
RUN apt-get update -qq && apt-get install -y build-essential

ENV APP_ROOT /usr/src/app
RUN mkdir -p $APP_ROOT
WORKDIR $APP_ROOT
COPY Gemfile* $APP_HOME/
COPY data/ $APP_ROOT/
RUN bundle install

# Start server
ENV PORT 3000
EXPOSE 3000
CMD ["ruby", "/usr/src/app/test.rb"]

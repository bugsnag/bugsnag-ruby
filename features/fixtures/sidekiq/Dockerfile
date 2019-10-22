ARG RUBY_TEST_VERSION
FROM ruby:$RUBY_TEST_VERSION

WORKDIR /bugsnag
COPY temp-bugsnag-lib ./

ARG APP_PATH

WORKDIR $APP_PATH

ARG SIDEKIQ_VERSION
ENV SIDEKIQ_VERSION $SIDEKIQ_VERSION

COPY app/Gemfile $APP_PATH
RUN bundle install

COPY app/ $APP_PATH

CMD ["bundle", "exec", "sidekiq", "-r", "./app.rb"]
ARG RUBY_TEST_VERSION
FROM ruby:$RUBY_TEST_VERSION

WORKDIR /bugsnag
COPY temp-bugsnag-lib ./

ARG APP_PATH

WORKDIR /app/

COPY app/Gemfile Gemfile
ARG SIDEKIQ_VERSION
ENV SIDEKIQ_VERSION $SIDEKIQ_VERSION

RUN bundle install

COPY app/ /app/

CMD bundle exec sidekiq -r ./app.rb

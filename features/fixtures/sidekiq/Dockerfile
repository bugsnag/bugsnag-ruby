ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION

WORKDIR /bugsnag
COPY temp-bugsnag-lib ./

WORKDIR /usr/src/app

ARG SIDEKIQ_VERSION
ENV SIDEKIQ_VERSION $SIDEKIQ_VERSION

COPY app/Gemfile /usr/src/app/
RUN bundle install

COPY app/ /usr/src/app

CMD ["bundle", "exec", "sidekiq", "-r", "./app.rb"]
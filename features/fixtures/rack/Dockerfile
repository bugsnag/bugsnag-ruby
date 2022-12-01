ARG RUBY_TEST_VERSION
FROM ruby:$RUBY_TEST_VERSION

WORKDIR /bugsnag
COPY temp-bugsnag-lib ./

WORKDIR /usr/src/app
COPY app/Gemfile /usr/src/app/

ARG RACK_VERSION
ENV RACK_VERSION $RACK_VERSION

RUN bundle install

COPY app/ /usr/src/app

CMD ["bundle", "exec", "ruby", "app.rb"]

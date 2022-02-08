ARG RUBY_TEST_VERSION
FROM ruby:$RUBY_TEST_VERSION

WORKDIR /bugsnag
COPY temp-bugsnag-lib ./

WORKDIR /usr/src/app
COPY app/Gemfile /usr/src/app/

ARG QUE_VERSION
ENV QUE_VERSION $QUE_VERSION

RUN bundle install

COPY app/ /usr/src/app

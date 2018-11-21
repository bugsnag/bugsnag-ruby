ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION

WORKDIR /bugsnag
COPY temp-bugsnag-lib ./

WORKDIR /usr/src/app
COPY app/Gemfile /usr/src/app/
RUN bundle install

COPY app/ /usr/src/app

RUN bundle exec rake rails:update:bin
RUN bundle exec bin/rails generate delayed_job:active_record
RUN bundle exec rake db:migrate

CMD ["bundle", "exec", "rake", "jobs:work"]

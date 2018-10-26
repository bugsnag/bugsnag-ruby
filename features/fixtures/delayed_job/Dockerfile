ARG ruby_version
FROM ruby:$ruby_version

WORKDIR /bugsnag
COPY *.gem ./
RUN gem unpack bugsnag*.gem /bugsnag

WORKDIR /usr/src/app
COPY app/Gemfile /usr/src/app/
RUN bundle install

COPY app/ /usr/src/app

RUN bundle exec rails generate delayed_job:active_record
RUN bundle exec rake db:migrate

CMD ["bundle", "exec", "rake", "jobs:work"]

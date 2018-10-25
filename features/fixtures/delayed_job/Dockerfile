ARG ruby_version
FROM ruby:$ruby_version

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY app/Gemfile /usr/src/app/
RUN bundle install

COPY app/ /usr/src/app

RUN bundle exec rails generate delayed_job:active_record
RUN bundle exec rake db:migrate

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]

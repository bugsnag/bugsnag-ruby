ARG RUBY_TEST_VERSION
FROM ruby:$RUBY_TEST_VERSION

RUN apt-get update

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get install -y nodejs yarn

WORKDIR /bugsnag
COPY temp-bugsnag-lib ./

WORKDIR /usr/src/app
COPY app/Gemfile /usr/src/app/
RUN bundle install

RUN cat Gemfile.lock

COPY app/ /usr/src/app

RUN bundle exec rake db:migrate

RUN mv /usr/src/app/bin-copy /usr/src/app/bin

# RUN bundle exec rake rails:update:bin

ENV RUBYOPT='--disable-did_you_mean'

CMD ["bundle", "exec", "bin/rails", "s", "-b", "0.0.0.0"]

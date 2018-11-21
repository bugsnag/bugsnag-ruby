ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION

WORKDIR /bugsnag
COPY temp-bugsnag-lib ./

WORKDIR /usr/src/app
COPY app/Gemfile /usr/src/app/
RUN bundle install

COPY . /usr/src/app
ENV QUEUE=*

CMD ["bundle", "exec", "rake", "resque:work"]

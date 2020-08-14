ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION

WORKDIR /bugsnag
COPY temp-bugsnag-lib ./

ARG APP_PATH

WORKDIR $APP_PATH

COPY app/Gemfile .
RUN bundle install

COPY app/ .

CMD ["./run.sh"]

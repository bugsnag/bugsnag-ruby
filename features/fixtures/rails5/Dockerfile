ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION

ARG APP_PATH

RUN mkdir -p $APP_PATH
WORKDIR $APP_PATH

COPY app/Gemfile $APP_PATH
RUN bundle install

COPY app $APP_PATH

CMD ["bundle", "exec", "bin/rails", "s", "-b", "0.0.0.0"]

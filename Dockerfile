FROM duodealer/ruby:latest

ENV BABEL_ENV production
ENV RAILS_ENV production

RUN apk update && \
  apk upgrade && \
  apk add \
  --no-cache \
  nodejs-current \
  curl \
  automake \
  libtool \
  pkgconfig \
  autoconf \
  postgresql-dev \
  postgresql-libs

ONBUILD COPY Gemfile* /tmp/
ONBUILD COPY package.json /tmp/
ONBUILD COPY yarn.lock /tmp/
ONBUILD WORKDIR /tmp
ONBUILD RUN bundle install

ONBUILD ENV app /app
ONBUILD RUN mkdir $app
ONBUILD WORKDIR $app
ONBUILD ADD . $app

ONBUILD RUN mkdir tmp/sockets -p
ONBUILD RUN mkdir tmp/pids -p
ONBUILD RUN mkdir tmp/cache -p

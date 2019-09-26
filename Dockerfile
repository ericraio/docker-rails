FROM duodealer/ruby:latest

ENV BABEL_ENV production
ENV RAILS_ENV production

RUN apk add --no-cache --virtual \
  nodejs-current \
  curl automake \
  libtool \
  pkgconfig \
  autoconf \
  && \
  cd /tmp && \
  git clone https://github.com/openvenues/libpostal && \
  cd ./libpostal && \
  ./bootstrap.sh && \
  ./configure --datadir=/usr/local/share/ && \
  make -j4 && \
  make install && \
  ldconfig

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

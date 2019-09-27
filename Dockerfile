FROM duodealer/ruby:latest

ENV BABEL_ENV production
ENV RAILS_ENV production
ARG COMMIT
ENV COMMIT ${COMMIT:-master}

RUN apk \
  --update \
  --no-cache \
  add --virtual .build-deps \
  nodejs-current \
  curl \
  automake \
  libtool \
  pkgconfig \
  autoconf \
  gcc \
  g++ \
  libtool \
  make \
  git \
  postgresql-dev \
  postgresql-libs
  
RUN git clone https://github.com/openvenues/libpostal -b $COMMIT
COPY ./*.sh /libpostal/ 
RUN cd /libpostal/ && \
  ./build_libpostal.sh

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

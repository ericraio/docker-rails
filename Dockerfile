FROM ruby:2.6.4-alpine3.10

ENV BABEL_ENV production
ENV RAILS_ENV production
ENV LIBPOSTAL_VERSION="1.1-alpha" \
    LIBPOSTAL_DOWNLOAD_URL="https://github.com/openvenues/libpostal/archive/v1.1-alpha.tar.gz" \
    LIBPOSTAL_DOWNLOAD_SHA="c8a88eed70d8c09f68e1e69bcad35cb397e6ef11b3314e18a87b314c0a5b4e3a"

RUN set -ex && \
  apk update && \
  apk upgrade && \
  apk add \
  --no-cache \
  --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main \
  nodejs-current \
  python \
  bash \
  findutils \
  binutils-gold \
  tar \
  linux-headers \
  build-base \
  xz \
  curl \
  automake \
  libtool \
  pkgconfig \
  autoconf \
  gcc \
  g++ \
  libtool \
  cmake \
  make \
  nodejs \
  npm \
  git \
  postgresql \
  postgresql-dev \
  postgresql-libs \
  chromium-chromedriver \
  imagemagick \
  tzdata \
  \
  && wget -O libpostal.tar.gz "$LIBPOSTAL_DOWNLOAD_URL" \
  && echo "$LIBPOSTAL_DOWNLOAD_SHA *libpostal.tar.gz" | sha256sum -c - \
  && mkdir -p /src  \
  && mkdir -p /data \
  && tar -xzf libpostal.tar.gz -C /src --strip-components=1 \
  && rm libpostal.tar.gz \
  && cd /src \
  && autoreconf -fi --warning=no-syntax --warning=no-portability \
  && ./configure --prefix=/usr --datadir=/data \
  && make -j "$(nproc)" \
  && make install \
  && rm -rf /src

ONBUILD COPY Gemfile* /tmp/
ONBUILD COPY package.json /tmp/
ONBUILD COPY yarn.lock /tmp/
ONBUILD WORKDIR /tmp
ONBUILD RUN echo "gem: --no-document" > ~/.gemrc 
ONBUILD RUN bundle install && npm install yarn -g 

ONBUILD ENV app /app
ONBUILD RUN mkdir $app
ONBUILD WORKDIR $app
ONBUILD ADD . $app

ONBUILD RUN mkdir tmp/sockets -p
ONBUILD RUN mkdir tmp/pids -p
ONBUILD RUN mkdir tmp/cache -p

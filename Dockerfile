FROM duodealer/ruby:latest

ENV BABEL_ENV production
ENV RAILS_ENV production
ENV LIBPOSTAL_VERSION="1.1-alpha" \
    LIBPOSTAL_DOWNLOAD_URL="https://github.com/openvenues/libpostal/archive/v1.1-alpha.tar.gz" \
    LIBPOSTAL_DOWNLOAD_SHA="c8a88eed70d8c09f68e1e69bcad35cb397e6ef11b3314e18a87b314c0a5b4e3a"

RUN set -ex && \
  apk upgrade && \
  apk update && \
  apk \
  add \
  --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main \
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
  postgresql \
  postgresql-dev \
  postgresql-libs && \
  wget -O libpostal.tar.gz "$LIBPOSTAL_DOWNLOAD_URL" && \
  echo "$LIBPOSTAL_DOWNLOAD_SHA *libpostal.tar.gz" | sha256sum -c - \
  \
  && mkdir -p /src  \
  && mkdir -p /data \
  \
  && tar -xzf libpostal.tar.gz -C /src --strip-components=1 \
  && rm libpostal.tar.gz \
  && cd /src \
  \
  && autoreconf -fi --warning=no-syntax --warning=no-portability \
  && ./configure --prefix=/usr --datadir=/data \
  \
  && make -j "$(nproc)" \
  && make install \
  \
  && apk del .build-deps \
  && rm -rf /src

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

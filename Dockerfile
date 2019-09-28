FROM duodealer/ruby:latest

ENV BABEL_ENV production
ENV RAILS_ENV production
ENV LIBPOSTAL_VERSION="1.1-alpha" \
    LIBPOSTAL_DOWNLOAD_URL="https://github.com/openvenues/libpostal/archive/v1.1-alpha.tar.gz" \
    LIBPOSTAL_DOWNLOAD_SHA="c8a88eed70d8c09f68e1e69bcad35cb397e6ef11b3314e18a87b314c0a5b4e3a" \
    LIBV8_BRANCH=v5.9.211.38.1 \
    LIBV8_VERSION=5.9.211.38.1-x86_64-linux


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
  make \
  nodejs \
  git \
  postgresql \
  postgresql-dev \
  postgresql-libs \
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
  && rm -rf /src \
  \
  && cd / \
  && git clone -b $LIBV8_BRANCH --recursive git://github.com/cowboyd/libv8.git \
  && cd /libv8 \
  && git checkout v6.0.286.44.0beta1 vendor/.gclient \
  && git checkout v6.0.286.44.0beta1 vendor/.gclient_entries \
  && export GYP_DEFINES="$GYP_DEFINES linux_use_bundled_binutils=0 linux_use_bundled_gold=0" \
  && export PATH=/libv8/vendor/depot_tools:"$PATH" \
  && cd vendor \
  && DEPOT_TOOLS_UPDATE=0 gclient sync --with_branch_heads \
  && bundle install \
  && bundle exec rake binary \
  && gem install /libv8/pkg/libv8-$LIBV8_VERSION.gem \
  && mkdir /root/pkg \
  && mv /libv8/pkg/libv8-$LIBV8_VERSION.gem /root/pkg/ \
  && gem install mini_racer \
  && cd / \
  && rm -rf /libv8 /tmp/* /var/tmp/* /var/cache/apk/*QQ /usr/local/bundle/gems/libv8-$LIBV8_VERSION/vendor

RUN apk add libstdc++

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

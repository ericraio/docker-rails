FROM duodealer/ruby:latest

ENV BABEL_ENV production
ENV RAILS_ENV production
ENV LIBPOSTAL_VERSION="1.1-alpha" \
    LIBPOSTAL_DOWNLOAD_URL="https://github.com/openvenues/libpostal/archive/v1.1-alpha.tar.gz" \
    LIBPOSTAL_DOWNLOAD_SHA="c8a88eed70d8c09f68e1e69bcad35cb397e6ef11b3314e18a87b314c0a5b4e3a" \
    NODE_VERSION=v12.11.0 \
    NPM_VERSION=6 \
    YARN_VERSION=latest

RUN set -ex && \
  apk update && \
  apk upgrade && \
  apk add \
  --no-cache \
  --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main \
  nodejs-current \
  python 
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
  binutils-gold \
  gnupg \
  libstdc++ \
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
  && \
  for server in ipv4.pool.sks-keyservers.net keyserver.pgp.com ha.pool.sks-keyservers.net; do \
    gpg --keyserver $server --recv-keys \
      4ED778F539E3634C779C87C6D7062848A1AB005C \
      B9E2F5981AA6E0CD28160D9FF13993A75599653C \
      94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
      B9AE9905FFD7803F25714661B63B535A4C206CA9 \
      77984A986EBC2AA786BC0F66B01FBB92821C587A \
      71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
      FD3A5288F042B6850C66B31F09FE44734EB7990E \
      8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
      C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
      DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
      A48C2BEE680E841632CD4E44F07496B3EB3C1762 && break; \
  done && \
  curl -sfSLO https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}.tar.xz && \
  curl -sfSL https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt.asc | gpg -d -o SHASUMS256.txt && \
  grep " node-${NODE_VERSION}.tar.xz\$" SHASUMS256.txt | sha256sum -c | grep ': OK$' && \
  tar -xf node-${NODE_VERSION}.tar.xz && \
  cd node-${NODE_VERSION} && \
  curl -sfSL https://github.com/nodejs/node/archive/${NODE_VERSION}.tar.gz | tar -xz --strip-components=1 -- node-12.11.0/deps/v8/test/torque/test-torque.tq && \
  ./configure --prefix=/usr ${CONFIG_FLAGS} && \
  make -j$(getconf _NPROCESSORS_ONLN) && \
  make install && \
  cd / && \
  if [ -z "$CONFIG_FLAGS" ]; then \
    if [ -n "$NPM_VERSION" ]; then \
      npm install -g npm@${NPM_VERSION}; \
    fi; \
    find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
    if [ -n "$YARN_VERSION" ]; then \
      for server in ipv4.pool.sks-keyservers.net keyserver.pgp.com ha.pool.sks-keyservers.net; do \
        gpg --keyserver $server --recv-keys \
          6A010C5166006599AA17F08146C2130DFD2497F5 && break; \
      done && \
      curl -sfSL -O https://yarnpkg.com/${YARN_VERSION}.tar.gz -O https://yarnpkg.com/${YARN_VERSION}.tar.gz.asc && \
      gpg --batch --verify ${YARN_VERSION}.tar.gz.asc ${YARN_VERSION}.tar.gz && \
      mkdir /usr/local/share/yarn && \
      tar -xf ${YARN_VERSION}.tar.gz -C /usr/local/share/yarn --strip 1 && \
      ln -s /usr/local/share/yarn/bin/yarn /usr/local/bin/ && \
      ln -s /usr/local/share/yarn/bin/yarnpkg /usr/local/bin/ && \
      rm ${YARN_VERSION}.tar.gz*; \
    fi; \
  fi && \
  rm -rf ${RM_DIRS} /node-${NODE_VERSION}* /SHASUMS256.txt /tmp/* /var/cache/apk/* \
    /usr/share/man/* /usr/share/doc /root/.npm /root/.node-gyp /root/.config \
    /usr/lib/node_modules/npm/man /usr/lib/node_modules/npm/doc /usr/lib/node_modules/npm/html /usr/lib/node_modules/npm/scripts && \
  { rm -rf /root/.gnupg || true; }

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

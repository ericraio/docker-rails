FROM duodealer/ruby:latest

ENV RAILS_ENV production

RUN add-apt-repository ppa:eugenesan/ppa && apt-get update -qq -y

#################################
# Symlinking Nodejs for ubuntu
#   -- http://stackoverflow.com/questions/26320901/cannot-install-nodejs-usr-bin-env-node-no-such-file-or-directory
#################################
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update &&  apt-get install -qq -y nodejs npm yarn

RUN ln -s /usr/bin/nodejs /usr/bin/node

#################################
# Rails
#################################

# Libpostal
RUN cd /tmp && git clone https://github.com/openvenues/libpostal && cd ./libpostal && ./bootstrap.sh && ./configure --datadir=/usr/local/share/ && make -j4 && sudo make install && sudo ldconfig

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
RUN wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
RUN apt-get update

RUN apt-get install -qq -y bison imagemagick libmagickcore-dev libmagickwand-dev libjpeg-dev libpng-dev libtiff-dev libwebp-dev libpq-dev postgresql postgresql-contrib ghostscript libgs-dev gs-esp brotli yarn rsync lsof

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ONBUILD RUN mkdir /app
ONBUILD WORKDIR /app

ONBUILD ADD Gemfile /app/Gemfile
ONBUILD ADD Gemfile.lock /app/Gemfile.lock

ONBUILD RUN yarn install --production --pure-lockfile --silent --no-progress --no-audit --no-optional

ONBUILD RUN bundle install --deployment

ONBUILD ADD . /app

ONBUILD RUN mkdir tmp/sockets -p
ONBUILD RUN mkdir tmp/pids -p
ONBUILD RUN mkdir tmp/cache -p

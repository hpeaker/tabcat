FROM ubuntu:trusty

RUN apt-get update -y    ##this step will add 5-10 minutes in initial provision
RUN apt-get install -y software-properties-common build-essential
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update -y
RUN apt-get install curl tar vim git ruby2.2 ruby2.2-dev gem -y
#sudo npm install -g kanso coffee-script uglify-js coffeelint -y

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

#RUN echo "deb https://apache.bintray.com/couchdb-deb trusty main" \
#    | sudo tee -a /etc/apt/sources.list
#RUN curl -L https://couchdb.apache.org/repo/bintray-pubkey.asc \
#    | apt-key add -
#RUN apt-get update -y
#RUN apt-get install couchdb -y

#RUN apt-get autoremove
#RUN chown -R couchdb /var/run/couchdb
#RUN chown -R vagrant /home/vagrant/.npm
#do NOT install nodejs as root user
RUN apt-get install nodejs -y
RUN npm install -g npm
#@3.x-latest
#installing these globally for now until they can be used with gulp
RUN npm install -g kanso coffee-script uglify-js coffeelint -y
RUN gem install sass
#RUN gem install sass

ADD . /tabcat

#skipping npm install for now
RUN cd /tabcat && npm install

# There are some additional dependencies for the Makefiles
RUN apt-get install realpath -y

WORKDIR /tabcat

# Compile coffeescript to js
RUN coffee --compile console/js/*.coffee

#RUN coffee --compile core/js/*.coffee
RUN coffee --join core/js/tabcat.js --compile core/js/tabcat/*.coffee
RUN coffee --compile core/js/couchdb/adhoc/*.coffee
RUN coffee --compile core/js/couchdb/*.coffee

RUN coffee --print --compile tasks/dart/js/dart.coffee > tasks/dart/js/task.js
RUN coffee --print --compile tasks/digit-symbol/js/digit-symbol.coffee > tasks/digit-symbol/js/task.js
RUN coffee --compile tasks/examiner/js/*.coffee
RUN coffee --print --compile tasks/line-perception/js/line-perception.coffee > tasks/line-perception/js/task.js
RUN coffee --print --compile tasks/memory/js/memory.coffee > tasks/memory/js/task.js
RUN coffee --print --compile tasks/stargazer/js/stargazer.coffee > tasks/stargazer/js/task.js

RUN sed -i -e 's/\r$//' scripts/*

# DOCKER-VERSION 1.2.0

FROM       ubuntu:14.04
MAINTAINER James Watling "watling.james@gmail.com"

# Install dependency packages
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y software-properties-common
RUN apt-get install -y make gcc wget openjdk-6-jre
RUN apt-get install -y git
RUN apt-get clean

# Deploy rbenv and ruby-build
RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
ENV RBENV_ROOT /root/.rbenv
ENV PATH /root/.rbenv/bin:/root/.rbenv/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ADD ./rbenv.sh /etc/profile.d/rbenv.sh

# Install Ruby
RUN rbenv install 2.1.1
RUN rbenv global 2.1.1
RUN rbenv rehash

# Install Bundler
RUN gem install --no-ri --no-rdoc bundler

# Install Rails
RUN gem install rails-3.2.22

# Install Curl and Node.js (for asset pipeline)
RUN apt-get install -qq -y curl
RUN apt-get install -qq -y nodejs

# Install nginx
RUN add-apt-repository -y ppa:nginx/stable
RUN apt-get update
RUN apt-get install -qq -y nginx
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN chown -R www-data:www-data /var/lib/nginx
ADD nginx_sites.conf /etc/nginx/sites-enabled/default

# Publish port 80
EXPOSE 80

# Start nginx when container starts
ENTRYPOINT /usr/sbin/nginx

# Install foreman
RUN gem install foreman

# Add default foreman config
ADD Procfile /home/rails/Procfile

# Install Unicorn
RUN gem install unicorn

# Add default unicorn config
ADD unicorn.rb /home/rails/config/unicorn.rb

# Install MySQL (for mysql, mysql2 gem)
RUN apt-get install -qq -y libmysqlclient-dev
RUN gem install mysql2

# Install Redis
RUN apt-get install -qq -y python-pip redis-server

# Setting up Rails app
WORKDIR /home/rails
ONBUILD ADD Gemfile /home/rails/Gemfile
ONBUILD ADD Gemfile.lock /home/rails/Gemfile.lock
ONBUILD RUN bundle install --without development test
ONBUILD ADD . /home/rails

# Set ENV Variables
ENV RAILS_ENV development

CMD bundle exec bin/server

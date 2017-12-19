# starting with ubuntu...
FROM ubuntu:16.04

RUN  export DEBIAN_FRONTEND=noninteractive
ENV  DEBIAN_FRONTEND noninteractive
RUN  dpkg-divert --local --rename --add /sbin/initctl

# get python stuff
RUN apt-get update
RUN apt-get install -y software-properties-common python-software-properties dialog apt-utils wget
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt xenial-pgdg main" >> /etc/apt/sources.list'
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update
RUN apt-get install -y python3-pip python3-dev libpq-dev nginx
RUN apt-get install -y postgresql-9.6
RUN apt-get install -y postgresql-9.6-postgis-2.3 postgresql-contrib-9.6 postgis postgresql-9.6-postgis-2.3-scripts

# for certbot
RUN apt-get update
RUN apt-get install software-properties-common -y
RUN add-apt-repository ppa:certbot/certbot
RUN apt-get update
RUN apt-get install python-certbot-nginx -y

# now get pip
RUN pip3 install --upgrade pip
RUN pip3 install virtualenv

# make working directory
RUN mkdir /code
RUN mkdir -p /code/logs
RUN mkdir /logs

# Touch log files
RUN touch /code/logs/gunicorn.log
RUN touch /code/logs/access.log

# change directory
WORKDIR /code

# put requirements.txt
ADD requirements.txt /code/

# install pip stuff
RUN pip install -r requirements.txt

ADD . /code/

COPY ./docker-entrypoint.sh /
COPY ./django_nginx.conf /etc/nginx/sites-available/
RUN ln -s /etc/nginx/sites-available/django_nginx.conf /etc/nginx/sites-enabled
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
ENTRYPOINT ["/docker-entrypoint.sh"]

# start certbot stuff
# READ: https://certbot.eff.org/#ubuntuxenial-nginx
RUN certbot --nginx -c

# Automating renewal
# The Certbot packages on your system come with a cron job that will
# renew your certificates automatically before they expire. Since
# Let's Encrypt certificates last for 90 days, it's highly advisable
# to take advantage of this feature. You can test automatic renewal
# for your certificates by running this command:

# RUN certbot renew --dry-run
# If that appears to be working correctly, you can arrange for automatic
# renewal by adding a cron or systemd job which runs the following:
# RUN certbot renew

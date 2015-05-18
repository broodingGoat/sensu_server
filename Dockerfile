FROM ubuntu:14.04

MAINTAINER Sushaant Mujoo <sushaant.mujoo@gmail.com>

# Get base packages & configure

#RUN apt-get update
RUN apt-get install -y git
RUN apt-get install -y curl
RUN apt-get install -y openssl
RUN apt-get install -y openssh-server
RUN apt-get install -y openssh-client
EXPOSE 22 3000 4567 5671 15672
RUN git clone https://github.com/broodingGoat/sensu_server.git

# Add users
RUN useradd sens -p sensu
RUN echo "sensu ALL=(ALL:ALL) ALL" | (EDITOR="tee -a" visudo)

# Installing Redis
RUN apt-get -y install redis-server
RUN service redis-server start


# Installing Rabbitmq
RUN echo "deb http://www.rabbitmq.com/debian/ testing main" | tee -a /etc/apt/sources.list.d/rabbitmq.list
RUN curl -L -o ~/rabbitmq-signing-key-public.asc http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
RUN apt-key add ~/rabbitmq-signing-key-public.asc
RUN apt-get install -y rabbitmq-server erlang-nox
RUN cd sensu_server/ssl; ./ssl_certs.sh clean && ./ssl_certs.sh generate
RUN mkdir /etc/rabbitmq/ssl
RUN cp sensu_server/ssl/server_cert.pem /etc/rabbitmq/ssl/cert.pem
RUN cp sensu_server/ssl/server_key.pem /etc/rabbitmq/ssl/key.pem
RUN cp sensu_server/ssl/server_key.pem /etc/rabbitmq/ssl/key.pem
RUN cp sensu_server/ssl/testca/cacert.pem /etc/rabbitmq/ssl/
RUN cp sensu_server/config/rabbitmq.config /etc/rabbitmq
RUN rabbitmq-plugins enable rabbitmq_management

# Configure Sensu Server
RUN wget -q http://repos.sensuapp.org/apt/pubkey.gpg -O- | sudo apt-key add -
RUN echo "deb     http://repos.sensuapp.org/apt sensu main" | tee -a /etc/apt/sources.list.d/sensu.list
RUN apt-get install -y sensu
RUN cp sensu_server/config/config.json /etc/sensu/
RUN mkdir -p /etc/sensu/ssl
RUN cp sensu_server/ssl/client_cert.pem /etc/sensu/ssl/cert.pem
RUN cp sensu_server/ssl/key.pem /etc/sensu/ssl/key.pem

# Configure uchiwa
RUN apt-get install -y uchiwa
RUN cp sensu_server/config/uchiwa.json /etc/sensu

# Configure startup
RUN service sensu-server start
RUN service sensu-client start
RUN service sensu-api start
RUN service uchiwa start

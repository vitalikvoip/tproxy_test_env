### Builder
FROM debian:buster
MAINTAINER Vitaliy Aleksandrov <vitalik.voip@gmail.com>

User root
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /usr/local/src
RUN apt-get update
RUN apt-get install -y build-essential git apache2 apache2-utils nano
RUN apt-get install -y htop tcpdump ngrep procps net-tools iptables iproute2 telnet

RUN git clone https://github.com/vitalikvoip/tproxy.git
WORKDIR tproxy
RUN make

COPY mpm_event.conf /etc/apache2/mods-enabled/mpm_event.conf

ENTRYPOINT ["tail", "-f", "/dev/null"]

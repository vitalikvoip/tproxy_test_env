.PHONY: build start stop login_client login_proxy login_server

build:
	docker build --tag="debian/tproxy:1.0" .

start:
	-docker network rm _net_1
	-docker network rm _net_2
	docker network create --driver=bridge _net_1 --subnet 10.100.0.0/24
	docker network create --driver=bridge _net_2 --subnet 10.200.0.0/24
	docker run -d --init --privileged --rm --network=_net_1 --ip 10.100.0.2   --name client debian/tproxy:1.0
	docker run -d --init --privileged --rm --network=_net_1 --ip 10.100.0.100 --name proxy  debian/tproxy:1.0
	docker network connect --ip 10.200.0.100 _net_2 proxy
	docker run -d --init --privileged --rm --network=_net_2 --ip 10.200.0.2 --name server debian/tproxy:1.0
	docker exec client ip r add 10.200.0.0/24 via 10.100.0.100 dev eth0
	docker exec client /bin/sh -c "echo 10.100.0.100 proxy  >> /etc/hosts"
	docker exec client /bin/sh -c "echo 10.200.0.2   server >> /etc/hosts"
	docker exec server ip r add 10.100.0.0/24 via 10.200.0.100 dev eth0
	docker exec server /bin/sh -c "echo 10.100.0.2 client >> /etc/hosts"
	docker exec server /etc/init.d/apache2 start
	docker exec proxy /usr/sbin/iptables -t mangle -N DIVERT
	docker exec proxy /usr/sbin/iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT
	docker exec proxy /usr/sbin/iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 80   -j TPROXY --on-port 1025 --on-ip 127.0.0.1 --tproxy-mark 0x1/0x1
	docker exec proxy /usr/sbin/iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 443  -j TPROXY --on-port 1025 --on-ip 127.0.0.1 --tproxy-mark 0x1/0x1
	docker exec proxy /usr/sbin/iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 8080 -j TPROXY --on-port 1025 --on-ip 127.0.0.1 --tproxy-mark 0x1/0x1
	docker exec proxy /usr/sbin/iptables -t mangle -A DIVERT -j MARK --set-xmark 0x1/0xffffffff
	docker exec proxy /usr/sbin/iptables -t mangle -A DIVERT -j ACCEPT
	docker exec proxy /sbin/ip rule add fwmark 1 lookup 100
	docker exec proxy /sbin/ip route add local 0.0.0.0/0 dev lo table 100
	docker exec proxy ./tproxy &

stop:
	docker stop client
	docker stop proxy
	docker stop server
	docker network rm _net_1
	docker network rm _net_2

login_client:
	docker exec -it client /bin/bash

login_proxy:
	docker exec -it proxy /bin/bash

login_server:
	docker exec -it server /bin/bash

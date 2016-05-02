#!/bin/bash
# Used to create certs with IP Sans, for nodes without cloud DNS and hard coded, nondynamic IPs (vagrant)
if [ -z "$1" ] || [ -z "$2" ] ; then
  echo "Usage: ./create_with_ip_sans.sh MASTER_NUM IP"
  exit 1
fi

cd `dirname $0`

nodeName=$1
IP=$2

#Generate Client-Server
echo client server
file=certs/$nodeName-server.json
cat core-ip.json | sed "s/__XX/$nodeName/g" | sed "s/__IP/$IP/g" > $file
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem \
  -config=ca-config.json -profile=server $file \
  | cfssljson -bare certs/$nodeName-server

#Generate Server
echo server
file=certs/$nodeName.json

cat server-ip.json | sed "s/__XX/$nodeName/g" | sed "s/__IP/$IP/g" > $file
cfssl gencert \-ca=certs/ca.pem -ca-key=certs/ca-key.pem \
  -config=ca-config.json -profile=client-server $file \
  | cfssljson -bare certs/$nodeName


#Generate TLS for Docker
echo docker
file=certs/$nodeName-docker.json
cat core-ip.json | sed "s/__XX/$nodeName/g" | sed "s/__IP/$IP/g" > $file
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem \
  -config=ca-config.json -profile=server $file \
  | cfssljson -bare certs/$nodeName-docker


#Generate TLS for Docker Swarm
echo docker swarm
file=certs/$nodeName-swarm.json
cat core-ip.json | sed "s/__XX/$nodeName/g" | sed "s/__IP/$IP/g" > $file
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem \
  -config=ca-config.json -profile=server $file \
  | cfssljson -bare certs/$nodeName-swarm

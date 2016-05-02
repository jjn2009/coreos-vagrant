#!/bin/bash
# Base certs are those which are added to each node, ca, etcd peer cert, client cert
# CA: signs all of the other certificates, needed by Clients for communicating to TLS enabled services
# etcd peer cert: used for etcd peers to communicate with each other
# Client cert: Used with CA cert to communicate with services


cd `dirname $0`
#Create CA
cfssl gencert -initca ca-csr.json | cfssljson -bare certs/ca -

#Generate Server
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem -config=ca-config.json \
      -profile=server server.json | cfssljson -bare certs/server


#Generate Client
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem -config=ca-config.json \
      -profile=client client.json | cfssljson -bare certs/client

cp certs/client.pem docker/cert.pem
cp certs/client-key.pem docker/key.pem
cp certs/ca.pem docker/ca.pem

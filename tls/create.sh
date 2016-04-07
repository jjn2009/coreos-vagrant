if [ -z "$1" ] ; do
  echo "Usage: ./create.sh NUM_MASTER [NUM_WORKER]"
  exit 1
done

#Create CA
cfssl gencert -initca ca-csr.json | cfssljson -bare certs/ca -

#Generate Server
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem -config=ca-config.json -profile=server server.json | cfssljson -bare certs/server

#Generate Client-Server
for i in `seq $1`; do
  cfssl gencert \-ca=certs/ca.pem -ca-key=certs/ca-key.pem \
      -config=ca-config.json -profile=client-server core-master.json \
      | cfssljson -bare certs/core-master-`printf "%02d" $i`
done

#Generate Client-Server
if [ ! -z $2 ]; do
  for i in `seq $2`; do
    cfssl gencert \-ca=certs/ca.pem -ca-key=certs/ca-key.pem \
        -config=ca-config.json -profile=client-server core-master.json \
        | cfssljson -bare certs/core-worker-`printf "%02d" $i`
  done
done


#Generate Client
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare certs/client

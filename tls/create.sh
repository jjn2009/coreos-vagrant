if [ -z "$1" ] ; then
  echo "Usage: ./create.sh NUM_MASTER [NUM_WORKER]"
  exit 1
fi

cd `dirname $0`
#Create CA
cfssl gencert -initca ca-csr.json | cfssljson -bare certs/ca -

#Generate Server
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem -config=ca-config.json -profile=server server.json | cfssljson -bare certs/server

#Generate Client-Server
for i in `seq $1`; do
  padNum=`printf "%02d" $i`
  cat core-master.json | sed "s/__XX/$padNum/g" |\
    cfssl gencert \-ca=certs/ca.pem -ca-key=certs/ca-key.pem \
      -config=ca-config.json -profile=client-server - \
      | cfssljson -bare certs/core-master-$padNum
done

#Generate Client-Server
if [ ! -z $2 ] && [ "$2" != "0" ]; then
  for i in `seq $2`; do
    cfssl gencert \-ca=certs/ca.pem -ca-key=certs/ca-key.pem \
        -config=ca-config.json -profile=client-server core-master.json \
        | cfssljson -bare certs/core-worker-`printf "%02d" $i`
  done
fi


#Generate Client
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare certs/client

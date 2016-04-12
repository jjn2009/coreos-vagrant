if [ -z "$1" ] || [ -z "$2" ] ; then
  echo "Usage: ./create_with_ip_sans.sh MASTER_NUM IP"
  exit 1
fi

cd `dirname $0`


padNum=`printf "%02d" $1`

echo client server
#Generate Client-Server
file=certs/core-master-$padNum-server.json
cat core-master-ip.json | sed "s/__XX/$padNum/g" | sed "s/__IP/$2/g" > $file
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem \
  -config=ca-config.json -profile=server $file \
  | cfssljson -bare certs/core-master-$padNum-server

echo server
#Generate Server
file=certs/core-master-$padNum.json

cat server-ip.json | sed "s/__XX/$padNum/g" | sed "s/__IP/$2/g" > $file
cfssl gencert \-ca=certs/ca.pem -ca-key=certs/ca-key.pem \
  -config=ca-config.json -profile=client-server $file \
  | cfssljson -bare certs/core-master-$padNum

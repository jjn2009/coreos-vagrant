#Create CA
cfssl gencert -initca ca-csr.json | cfssljson -bare certs/ca -

#Generate Server
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem -config=ca-config.json -profile=server server.json | cfssljson -bare certs/server

#Generate Client-Server
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem -config=ca-config.json -profile=client-server core-master.json | cfssljson -bare certs/core-master-01

#Generate Client
cfssl gencert -ca=certs/ca.pem -ca-key=certs/ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare certs/client

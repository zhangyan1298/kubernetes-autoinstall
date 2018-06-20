#!/bin/sh
#Auto Install kubernetes cluster
#Deployment CA before download cfssl tools
soft_location=/usr/local/soft
bin_location=/usr/bin
ssl_source=/opt/kubernetes/ssl_source
ssl_prod=/etc/kubernetes/ssl

mkdir /usr/local/soft
mkdir -p /opt/kubernetes/ssl_source
mkdir -p /etc/kubernetes/ssl
get_name="cfssl_linux-amd64 cfssljson_linux-amd64"
for url_name in ${get_name[$@]}
do
wget  https://pkg.cfssl.org/R1.2/${url_name} -D /usr/local/soft || echo "get ${url_name} fail" 
chmod u+x $soft_location/${url_name}
mv $soft_location/${url_name}  ${bin_location} || "echo mv cfssl tools fail"
done
cd ${ssl_source}
yum -y install git && git init && git clone https://github.com/zhangyan1298/kubernetes-autoinstall.git
if [ test -d  kubernetes-autoinstall ]
then
cfssl_linux-amd64 gencert -initca ca-csr.json | cfssljson_linux-amd64 -bare ca
cfssl_linux-amd64 gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server-csr.json | cfssljson_linux-amd64 -bare server
cfssl_linux-amd64 gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server admin-csr.json | cfssljson -bare admin


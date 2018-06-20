#!/bin/sh
#Auto Install kubernetes cluster
#Deployment CA before download cfssl tools
mkdir /usr/local/soft
mkdir -p /opt/kubernetes/ssl_source
mkdir -p /etc/kubernetes/ssl
KUBE_APISERVER=https://$1
soft_location=/usr/local/soft
bin_location=/usr/bin
ssl_source=/opt/kubernetes/ssl_source
ssl_prod=/etc/kubernetes/ssl
get_name="cfssl_linux-amd64 cfssljson_linux-amd64"

rm -rf /opt/kubernetes/ssl_source/kubernetes-autoinstall


for url_name in ${get_name[$@]}
do
wget  https://pkg.cfssl.org/R1.2/${url_name} -P /usr/local/soft || echo "get ${url_name} fail"
chmod u+x $soft_location/${url_name}
mv $soft_location/${url_name}  ${bin_location} || "echo mv cfssl tools fail"
done

cd ${ssl_source}
yum -y install git sshpass && git init && git clone https://github.com/zhangyan1298/kubernetes-autoinstall.git

if [ -d  "kubernetes-autoinstall" ]
then
cd kubernetes-autoinstall
cfssl_linux-amd64 gencert -initca ca-csr.json | cfssljson_linux-amd64 -bare ca
cfssl_linux-amd64 gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server-csr.json | cfssljson_linux-amd64 -bare server
cfssl_linux-amd64 gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server admin-csr.json | cfssljson_linux-amd64 -bare admin
cfssl_linux-amd64 gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kube-proxy-csr.json | cfssljson_linux-amd64 -bare kube-proxy
cfssl_linux-amd64 gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server flanneld-csr.json | cfssljson_linux-amd64 -bare flanneld
mv *.{key,pem,csr}  $ssl_prod
openssl x509  -noout -text -in /opt/ssl/server.pem
fi

#COPY bootstrap file to node 
ssh-keygen  -t rsa -P "" -f ~/.ssh/id_rsa
if [ $# -gt 1 ]
then
#shift $1,because $1 is apiserver
shift
for nodes in "${@}"
do
#nedd set SSHPASS environment
#or run sshpass -p password
sshpass -e ssh-copy-id $nodes
ssh $nodes mkdir -p $ssl_prod
scp $ssl_prod/*.* $nodes:$ssl_prod
shift
done
fi
#install etcd server
tar xzvf $soft_location/{etcd-v3.2.18-linux-amd64,kubernetes.*,flannel-v0.10.0-linux-amd64}.tar.gz

cp etcd-v3.2.18-linux-amd64/{etcd,etcdctl} /usr/local/bin/
cp flannel-v0.10.0-linux-amd64/* /usr/local/bin/
cp kubernetes/node/bin/* /usr/local/bin/
cp kubernetes/server/bin{kubelet,kubectl,kube-apiserver,kube-controller,kube-scheduler} /usr/local/bin


cp *.service /usr/lib/systemd/system/



##call out sub-shell
function outcall {
for s in `ls |awk '/sh$/ && !/^auto/'`
do
pwd
 echo $s
source ./$s
done
}



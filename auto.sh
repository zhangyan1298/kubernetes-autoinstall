#!/bin/sh
#Auto Install kubernetes cluster
#Deployment CA before download cfssl tools
mkdir /usr/local/soft
mkdir -p /opt/kubernetes/ssl_source
mkdir -p /etc/kubernetes/ssl
mkdir -p /var/lib/etcd
mkidr -p /var/lib/kubelet
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
yum -y install git sshpass docker && git init && git clone https://github.com/zhangyan1298/kubernetes-autoinstall.git

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
tar xzvf $soft_location/etcd-v3.2.18-linux-amd64.tar.gz -C $soft_location
tar xzvf $soft_location/flannel-v0.10.0-linux-amd64.tar.gz -C $soft_location
tar xzvf $soft_location/kubernetes-server.tar.gz -C $soft_location
tar xzvf $soft_location/kubernetes-node*.tar.gz -C $soft_location

cp $soft_location/etcd-v3.2.18-linux-amd64/{etcd,etcdctl} /usr/local/bin/
cp $soft_location/flanneld /usr/local/bin/
cp $soft_location/kubernetes/node/bin/* /usr/local/bin/
cp $soft_location/kubernetes/server/bin/{kubelet,kubectl,kube-apiserver,kube-controller-manager,kube-scheduler} /usr/local/bin


#########################
cp *.service /usr/lib/systemd/system/
cp token.csv /etc/kubernetes
#########################enable
systemctl enable etcd
systemctl enable kube-apiserver
systemctl enable kube-scheduler
systemctl enable kube-controller-manager
systemctl enable kube-proxy
systemctl enable flanneld
systemctl enable docker
systemctl enable kubelet
systemctl start etcd
systemctl start kube-apiserver
############################



##call out sub-shell
function outcall {
for s in `ls |awk '/sh$/ && !/^auto/'`
do
pwd
 echo $s
source ./$s
done
}
outcall
########################start flanneld
systemctl start flanneld
########################start kube-controller-manager
systemctl start kube-controller-manager
########################start kube-scheduler
systemctl start kube-scheduler
########################start kubelet
systemctl start kubelet
########################start kube-proxy
systemctl start kube-proxy



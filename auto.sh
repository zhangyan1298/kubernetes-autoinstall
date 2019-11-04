
#!/bin/sh
#set -e
#Auto Install kubernetes cluster
#Deployment CA before download cfssl tools

###start before erase service exits
systemctl stop etcd
systemctl stop kube-controller-manager
systemctl stop kube-apiserver
systemctl stop kube-scheduler
systemctl stop kube-proxy
systemctl stop kubelet
systemctl stop flanneld
systemctl stop docker
rm -rf /var/lib/etcd
rm -rf /var/lib/kubelet
rm -rf /etc/kubernetes/ssl
###
####
mkdir /usr/local/soft
mkdir -p /opt/kubernetes/ssl_source
mkdir -p /etc/kubernetes/ssl
mkdir -p /var/lib/etcd
mkdir -p /var/lib/kubelet
mkdir -p /var/lib/kube-proxy
mkdir /etc/docker
KUBE_APISERVER=https://$1
etcd_ver=v3.2.24
flannel_ver=v0.11.0
soft_location=/opt/ball
bin_location=/usr/bin
ssl_source=/opt/kubernetes/ssl_source
ssl_prod=/etc/kubernetes/ssl
get_name="cfssl_linux-amd64 cfssljson_linux-amd64"
etcd_url=${KUBE_APISERVER}:2379
rm -rf /opt/kubernetes/ssl_source/kubernetes-autoinstall
rm -rf $soft_location/cfssl*
for url_name in ${get_name}
do
wget  https://pkg.cfssl.org/R1.2/${url_name} -P ${soft_location} || echo "get ${url_name} fail"
chmod u+x $soft_location/${url_name}
mv $soft_location/${url_name}  ${bin_location} || "echo mv cfssl tools fail"
done
cd ${ssl_source}
yum -y install git sshpass 
# 排除docker-ce-18.06.1.ce
git init && git clone https://github.com/zhangyan1298/kubernetes-autoinstall.git
if [ -n netstat -tnlp |grep ":443" ]
then
echo "443 port is use: please check!"
fi


if [ -d  "kubernetes-autoinstall" ]
then
#####关闭本地swap
swapoff -a
cd kubernetes-autoinstall
####替换原始masterIP及配置文件内的nodeIP
sed -i s/192.168.0.4/$1/g *
cfssl_linux-amd64 gencert -initca ca-csr.json | cfssljson_linux-amd64 -bare ca
cfssl_linux-amd64 gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server-csr.json | cfssljson_linux-amd64 -bare server
cfssl_linux-amd64 gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server admin-csr.json | cfssljson_linux-amd64 -bare admin
cfssl_linux-amd64 gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kube-proxy-csr.json | cfssljson_linux-amd64 -bare kube-proxy
cfssl_linux-amd64 gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server flanneld-csr.json | cfssljson_linux-amd64 -bare flanneld
mv *.{key,pem,csr}  $ssl_prod
openssl x509  -noout -text -in $ssl_prod/server.pem
fi


#install etcd server
tar xzvf $soft_location/etcd-${etcd_ver}-linux-amd64.tar.gz -C $soft_location
tar xzvf $soft_location/flannel-${flannel_ver}-linux-amd64.tar.gz -C $soft_location
tar xzvf $soft_location/kubernetes-server-linux-amd64.tar.gz -C $soft_location
tar xzvf $soft_location/kubernetes-node-linux-amd64.tar.gz -C $soft_location

cp -f $soft_location/etcd-${etcd_ver}-linux-amd64/{etcd,etcdctl} /usr/local/bin/
cp -f $soft_location/flanneld /usr/local/bin/
cp -f $soft_location/mk-docker-opts.sh /usr/local/bin
cp -f $soft_location/kubernetes/node/bin/* /usr/local/bin/
cp -f $soft_location/kubernetes/server/bin/{kubelet,kubectl,kube-apiserver,kube-controller-manager,kube-scheduler} /usr/local/bin


#########################
pwd
cp *.service /usr/lib/systemd/system/
cp token.csv /etc/kubernetes
cp daemon.json /etc/docker
#########################enable
systemctl daemon-reload
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
systemctl start docker
########################start kube-controller-manager
systemctl start kube-controller-manager
########################start kube-scheduler
systemctl start kube-scheduler
########################start kube-proxy
systemctl start kube-proxy
#################################################

#COPY bootstrap file to node 
#已经打通了ssh下面这里就不需要重新生成了
#ssh-keygen  -t rsa -P "" -f ~/.ssh/id_rsa
if [ $# -gt 1 ]
then
#shift $1,because $1 is apiserver
shift
for nodes in "${@}"
do
#nedd set SSHPASS environment
#or run sshpass -p password
#sshpass -e ssh-copy-id $nodes
ssh $nodes systemctl stop kube-proxy
ssh $nodes systemctl stop flanneld
ssh $nodes systemctl stop docker
ssh $nodes systemctl stop kubelet

ssh $nodes rm -rf /var/lib/kubelet
ssh $nodes rm -rf /etc/kubernetes/ssl
ssh $nodes mkdir -p $ssl_prod
ssh $nodes mkdir /var/lib/kube-proxy
ssh $nodes mkdir /var/lib/kubelet
ssh $nodes yum -y install docker-ce-18.06.1.ce
ssh $nodes "swapoff -a"
scp $ssl_prod/* $nodes:$ssl_prod
scp docker.service kubelet.service kube-proxy.service flanneld.service $nodes:/usr/lib/systemd/system/
scp $soft_location/flanneld $nodes:/usr/local/bin/
scp $soft_location/mk-docker-opts.sh $nodes:/usr/local/bin
ssh $nodes sed -i s/${KUBE_APISERVER##https://}/$nodes/g /usr/lib/systemd/system/kubelet.service 
ssh $nodes sed -i s/${KUBE_APISERVER##https://}/$nodes/g /usr/lib/systemd/system/kube-proxy.service 
scp $soft_location/kubernetes/node/bin/* $nodes:/usr/local/bin
scp daemon.json $nodes:/etc/docker
shift
for services in "kubelet.service kube-proxy.service flanneld.service docker"
do
ssh $nodes systemctl daemon-reload
ssh $nodes systemctl enable $services
ssh $nodes systemctl start $services
done
done
fi
#start local kubelet service. after scp keys to nodes run.
systemctl start kubelet

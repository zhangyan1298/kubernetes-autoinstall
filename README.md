# kubernetes-autoinstall
##fix 
etcdctl --endpoints=https://192.168.0.4:2379 --ca-file=/etc/kubernetes/ssl/ca.pem --cert-file=/etc/kubernetes/ssl/flanneld.pem --key-file=/etc/kubernetes/ssl/flanneld-key.pem set /atomic.io/network/config '{"Network":"10.0.0.0/16"}'
Error:  client: etcd cluster is unavailable or misconfigured; error #0: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "tticar ca")

error #0: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "tticar ca")

fix add auto.sh follow 
systemctl stop etcd
rm -rf /var/lib/etcd



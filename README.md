# kubernetes-autoinstall
##fix 
etcdctl --endpoints=https://192.168.0.4:2379 --ca-file=/etc/kubernetes/ssl/ca.pem --cert-file=/etc/kubernetes/ssl/flanneld.pem --key-file=/etc/kubernetes/ssl/flanneld-key.pem set /atomic.io/network/config '{"Network":"10.0.0.0/16"}'
Error:  client: etcd cluster is unavailable or misconfigured; error #0: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "tticar ca")

error #0: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "tticar ca")

fix add auto.sh follow 
systemctl stop etcd
rm -rf /var/lib/etcd


############调试脚本保存{0.4 192.168。0.5}
定位脚本报错在40行
发现40行调用了${get_name[$@]}
去除{}后报错消失
发现${get_name[$@]}
与$get_name[$@]
是有区别的。

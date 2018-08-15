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
这里直接用变量名即可，上门的修复忽略！
####
Jun 22 03:23:56 k8s-node kubelet: E0622 03:23:56.533527    1848 reflector.go:205] k8s.io/kubernetes/pkg/kubelet/config/apiserver.go:47: Failed to list *v1.Pod: Get https://192.168.0.4/api/v1/pods?fieldSelector=spec.nodeName%3D192.168.0.5&limit=500&resourceVersion=0: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "tticar ca")
nodes kubelet 运行报错

检查发现

openssl x509  -noout -text -in /etc/kubernetes/ssl/kubelet.crt
此行为
 Subject: CN=192.168.0.4@1529635917
是另一个kubelet节点的信息。
那么原因是脚本在copy keys时候 另外节点已经启动了kubelet服务，已生成了kubelet.crt 导致拷贝到节点上，节点的kubelet启动失败
##########
使用前需要手动修改的地方有
1.server-csr 证书需要包括使用到的节点IP，或主机名包括在其中
2.使用方法auth.sh xxip xxip 
$1 为master 后续的都是node节点
。

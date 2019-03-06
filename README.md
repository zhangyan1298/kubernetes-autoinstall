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
这里直接用变量名即可，上面的修复忽略！
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

#20190305
update
增加变量位置
二进制文件路径更改到/usr/local/bin
修改server-config.json 增加此次部署得ip
修改安装docker-ce 得版本为docker-ce-18.06.1.ce
docker.services 去除--seccomp-profile 及after wants 配置，因为系统与软件版本不对应
#20190306
update
docker-ce-18.06.1 服务启动文件为dockerd 与 release不同得是docker-current 
还有docker-ce-.18.09.x 启动文件为docker-ce
##20190306
update:
环境：配置好ansible ssh打通
执行ansible -v k8s-node.yaml 下载所有安装包
在控制主机上执行auto.sh apiserver node node 

。

#!/bin/bash
etcd_url=${etcd_url:-default}
etcdctl \
  --endpoints=${etcd_url} \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/kubernetes/ssl/flanneld.pem \
  --key-file=/etc/kubernetes/ssl/flanneld-key.pem \
set /atomic.io/network/config  '{"Network":"172.20.0.0/16"}'

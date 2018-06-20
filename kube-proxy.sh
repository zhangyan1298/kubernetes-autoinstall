#!/bin/bash
KUBE_APISERVER=${KUBE_APISERVER:-default}
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig
kubectl config set-credentials kube-proxy \
  --token=3796fac2e6fae7a23aefb5b7fdb4d731 \
  --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
  --embed-certs=true \
  --client-key=/etc/kubernetes/ssl/kube-proxy-key.pem \
  --kubeconfig=kube-proxy.kubeconfig
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
kubectl config use-context kubernetes --kubeconfig=kube-proxy.kubeconfig
mv kube-proxy.kubeconfig /etc/kubernetes/ssl

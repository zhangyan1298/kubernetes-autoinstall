#!/bin/sh
#Auto Install kubernetes cluster
#Deployment CA before download cfssl tools
soft_location=/usr/local/soft
bin_location=/usr/bin
mkdir /usr/local/soft
get_name="cfssl_linux-amd64 cfssljson_linux-amd64"
for url_name in ${get_name[$@]}
do
wget  https://pkg.cfssl.org/R1.2/${url_name} -D /usr/local/soft || echo "get ${url_name} fail" 
chmod u+x $soft_location/${url_name}
mv $soft_location/${url_name}  ${bin_location} || "echo mv cfssl tools fail"
done



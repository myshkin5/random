#!/usr/bin/env bash

set -xeuEo pipefail

mkdir -p ecc
cd ecc

openssl ecparam \
  -genkey \
  -name prime256v1 \
  -out root-key.pem

openssl req \
  -new \
  -sha256 \
  -key root-key.pem \
  -nodes \
  -out csr.csr \
  -subj "/C=US/ST=Colorado/L=Longmont/O=Aspen Mesh/CN=''"

CONFIG="
[req]
distinguished_name=dn
[ dn ]
[ ext ]
basicConstraints=CA:TRUE,pathlen:0
"

openssl req \
  -config <(echo "$CONFIG") \
  -key root-key.pem \
  -in csr.csr \
  -x509 \
  -extensions ext \
  -days 365 \
  -nodes \
  -copy_extensions copyall \
  -out root-cert.pem

cp root-cert.pem ca-cert.pem
cp ca-cert.pem cert-chain.pem

tail +4 root-key.pem > ca-key.pem

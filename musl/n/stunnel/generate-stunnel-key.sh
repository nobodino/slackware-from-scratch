#!/bin/sh
USE_DH=0

openssl req -new -x509 -days 365 -nodes \
  -config ./openssl.cnf -out stunnel.pem -keyout stunnel.pem

test $USE_DH -eq 0 || openssl gendh >> stunnel.pem

openssl x509 -subject -dates -fingerprint -noout \
  -in stunnel.pem

chmod 600 stunnel.pem
rm -f stunnel.rnd

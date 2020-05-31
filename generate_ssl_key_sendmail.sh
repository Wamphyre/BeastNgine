#!/bin/bash

cd /etc/mail/certs && openssl dhparam -out dh.param 4096

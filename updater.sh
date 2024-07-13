#!/bin/bash

pkg update && pkg upgrade -y;

freebsd-update fetch && freebsd-update install;

rm -rf /usr/ports

git clone --depth 1 https://git.FreeBSD.org/ports.git /usr/ports

pkg clean -y;

pkg autoremove -y;

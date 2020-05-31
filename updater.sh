#!/bin/bash

pkg update && pkg upgrade -y;

freebsd-update fetch && freebsd-update install;

portsnap fetch auto;

pkg clean -y;

pkg autoremove -y;

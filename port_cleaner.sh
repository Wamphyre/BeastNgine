#!/bin/bash
#
# Search for ports that contain a "work" subdirectory,
# then go into that port directory and perform a
# make clean

for i in `find /usr/ports -name work -type d`
 do
  cd `echo "$i" | sed 's/\/[^\/]*$/\//'`
  make clean
 done

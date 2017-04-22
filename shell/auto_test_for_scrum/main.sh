#!/bin/bash
rm -rf /home/vpd_test
mkdir /home/vpd_test

for((i=0;;i++))
do
    sh vpd_auto_test.sh
    [ $? -eq 0 ] || {
        break
    }
done

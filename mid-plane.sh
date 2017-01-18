#!/bin/bash
#mid-plane eeprom test 
#
# 2. 
#

# Default variables
# Default variables
: ${IP:=192.168.200.42}

[ -n "$1" ] && IP=$1

dec2hex(){
    printf "%x" $1
}

i1=43
i2=0
passtest=1
while :; do
	ipmitool -H $IP -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x00 0x$(printf %.2x $i1) 0x$(printf %.2x $i2) 0x$(printf %.2x $i2)
	sleep 0.02
	rtxt=`ipmitool -H $IP -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x01 0x$(printf %.2x $i1) 0x$(printf %.2x $i2)`
	sleep 0.02
	rval=$((16#$(($rtxt))))

	if [ $i2 != $rval ]; then
		echo "read_write inconsistent offset:0x$i1$i2,write:$i2,read:$rval"
		passtest=0
		break	
	fi

	if [ "$i2" = "255" ]; then
		i1=$(($i1+1))
		i2=0
	else
		i2=$(($i2+1))
	fi

	if [ "$i1" = "255" ]; then
		if [ "$i2" = "255" ]; then
			ipmitool -H $IP -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x00 0x$(printf %.2x $i1) 0x$(printf %.2x $i2) 0x$(printf %.2x $i2)
			sleep 0.02
			rtxt=`ipmitool -H $IP -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x01 0x$(printf %.2x $i1) 0x$(printf %.2x $i2)`
			sleep 0.02
			rval=$((16#$(($rtxt))));

			if [ $i2 != $rval ]; then
				echo "read_write inconsistent offset:0x$i1$i2,write:$i2,read:$rval"
				passtest=0
				break	
			fi

			echo 0x$i1$i2
			break
		fi
	fi
done

if [ $passtest = 1 ]; then
	echo "write-read EEPROM test ok"
fi

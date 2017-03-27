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

#reserved space for midplane vpd start from 0x2B00,0x2B(hex)=43(dec)
offset_h=43
offset_l=0

i1=$offset_h
i2=$offset_l
passtest=1
bytecount=$((16#$(($i2))))
testlimit=257
sleeptime=0.001
while :; do
	ipmitool -H $IP -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x00 0x$(printf %.2x $i1) 0x$(printf %.2x $i2) 0x$(printf %.2x $i2)
	echo "ipmitool -H $IP -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x00 0x$(printf %.2x $i1) 0x$(printf %.2x $i2) 0x$(printf %.2x $i2)"
	sleep $sleeptime
	rtxt=$(echo $(ipmitool -H $IP -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x01 0x$(printf %.2x $i1) 0x$(printf %.2x $i2)))
	sleep $sleeptime
	rval=$((16#$(echo $rtxt)))
#	echo "rval = $rval"
#	rval=5 #for test when read_write inconsistent
	bytecount=$(($bytecount+1))

	if [ $i2 != $rval ]; then
		echo "read_write inconsistent offset:0x$(printf %.2x $i1)$(printf %.2x $i2),write:0x$(printf %.2x $i2),read:0x$(printf %.2x $rval)"
		passtest=0
		break	
	else

		echo "read_write equal offset:0x$(printf %.2x $i1)$(printf %.2x $i2),write:0x$(printf %.2x $i2),read:0x$(printf %.2x $rval)"
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
			echo "ipmitool -H $IP -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x00 0x$(printf %.2x $i1) 0x$(printf %.2x $i2) 0x$(printf %.2x $i2)"
			sleep $sleeptime
			rtxt=`ipmitool -H $IP -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x01 0x$(printf %.2x $i1) 0x$(printf %.2x $i2)`
			sleep $sleeptime
			rval=$((16#$(($rtxt))));
			bytecount=$(($bytecount+1))
			if [ $i2 != $rval ]; then
		                echo "read_write inconsistent offset:0x$(printf %.2x $i1)$(printf %.2x $i2),write:0x$(printf %.2x $i2),read:0x$(printf %.2x $rval)"
				passtest=0
				break
			else	
				echo "read_write equal offset:0x$(printf %.2x $i1)$(printf %.2x $i2),write:0x$(printf %.2x $i2),read:0x$(printf %.2x $rval)"
			fi

			echo 0x$i1$i2
			break
		fi
	fi


	if [ $testlimit != 0 ]; then
		if [ $testlimit = $bytecount ]; then
			break
		fi
	fi
done

if [ $passtest = 1 ]; then
	echo "write-read EEPROM test ok"
fi

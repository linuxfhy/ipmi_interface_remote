#!/bin/bash


function execbmcipmicmd()
{
                                                   #BUS  Addr cnt
	writecmd="timeout -k1 1 ipmitool raw 0x06 0x52 0x09 0xAC 0x00"
	paraindex=2
	
	#use paramaters of the function to build wirte command
	while [ $(($paraindex)) -le $# ]	
	do
		writecmd="${writecmd} ${!paraindex}"
		paraindex=$(($paraindex+1))
	done
	
	#execute command and check whether execute successfully.
	${writecmd}
	wirtecmd_rc=$(($?))
    if [ ${wirtecmd_rc} != 0 ]; then
	    echo "command exec fail,cmd_W:${writecmd},cmd_rc:${wirtecmd_rc}"
		exit
	fi
	
	echo "cmd_W:${writecmd}"	
	
	#read data and check weather it equal to write-data
	readcmd="timeout -k1 1 ipmitool raw 0x06 0x52 0x09 0xAC"
	readcnt=$(($#-3))
	readcmd="${readcmd} 0x$(printf %.2x $readcnt) $2 $3"
	echo "cmd_R:${readcmd}"
	
	readresult=$(${readcmd})
	echo "read data is"${readresult}
	
	array=($readresult)
	
	i=0
	while [ $(($i)) -lt $readcnt ]	
	do
		j=$(($i+4))
		if [ $((16#${array[$i]})) != $((${!j})) ]; then
		    write_ok=0
			echo "read/write data inconsistent:index($i),writedata:$((${!j})),readdata:$((16#${array[$i]}))"
			exit
		fi
		i=$(($i+1))
	done
}

#script start exec from here
write_ok=1

#vpd_can_fru_part_number_e	
#85y6116
              #cnt of_h of_l data...
execbmcipmicmd 0x00 0X2B 0x93 0x38 0x35 0x79 0x36 0x31 0x31 0x36


#vpd_can_fru_identity_e
#11S 85Y6112 YHU999 00P5E3
execbmcipmicmd 0x00 0X2B 0x80 0x38 0x35 0x59 0x36 0x31 0x31 0x32
execbmcipmicmd 0x00 0X2B 0x87 0x59 0x48 0x55 0x39 0x39 0x39
execbmcipmicmd 0x00 0X2B 0x8D 0x30 0x30 0x50 0x35 0x45 0x33


if [ $write_ok = 1 ]; then
    echo "write canister vpd OK"
else
    echo "write canister vpd fail"
fi
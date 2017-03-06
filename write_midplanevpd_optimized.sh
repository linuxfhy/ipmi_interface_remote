#!/bin/bash
#ipmitool cmnd case:
#                                                           BUS  Addr cnt off_h off_l data....
#ipmitool -H 192.168.200.42 -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x00 0x2B 0x00 

function getmasterCMCip()
{
    ip=$(ipmitool raw 0x30 0x14)
	array=($ip)
	i=0
	ipaddr[2]=0
	
	while [ $(($i)) -lt 2 ]
	do
		ipaddr[$i]="$((16#${array[4+$((8*$i))]})).$((16#${array[5+$((8*$i))]})).$((16#${array[6+$((8*$i))]})).$((16#${array[7+$((8*$i))]}))"
		echo "cmc${i}_eth1_ip:"${ipaddr[$i]}
		readcmd="timeout -k1 1 ipmitool -H ${ipaddr[$i]} -U admin -P admin raw 0x30 0x23"
		readresult=$(${readcmd})
		
		cmd_rc=$(($?))
		if [ ${cmd_rc} != 0 ]; then
			echo "check cmc${i} is master fail,cmd_rc:${cmd_rc}(124:timeout,127:cmd not exist)"
		fi
		
		echo "cmc${i} is: "${readresult}"(1:master,0:slave)"
		
		if [ $((${readresult})) = 1 ]; then
			masterCMCip=${ipaddr[$i]}
			return 0
		fi
	done
	
    return 1
}
function execcmcipmicmd()
{
    getmasterCMCip	
	cmd_rc=$(($?))
    if [ ${cmd_rc} != 0 ]; then
	    echo "get master cmc ip fail,cmd_rc is ${cmd_rc}"
		exit
	fi
                                                                                       #BUS  Addr cnt
	writecmd="timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x00"
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
	readcmd="timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0"
	readcnt=$(($#-3))
	readcmd="${readcmd} 0x$(printf %.2x $readcnt) $2 $3"
	echo "cmd_R:${readcmd}"
	
	readresult=$(${readcmd})
	echo "read data is"${readresult}
	echo
	echo
	echo

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
masterCMCip=192.168.200.142

#fru_identify:
#11S 85Y5962 YHU999 4G0284
#0x31 0x31 0x53 
#0x38 0x35 0x59 0x35 0x39 0x36 0x32 
#0x59 0x48 0x55 0x39 0x39 0x39 
#0x34 0x47 0x30 0x32 0x38 0x34
#cnt of_h of_l data...
execcmcipmicmd 0x00 0x2F 0x40 0x38 0x35 0x59 0x35 0x39 0x36 0x32 
execcmcipmicmd 0x00 0x2F 0x47 0x59 0x48 0x55 0x39 0x39 0x39 
execcmcipmicmd 0x00 0x2F 0x4D 0x34 0x47 0x30 0x32 0x38 0x34
echo "write fru_identify:11S85Y5962YHU9994G0284, 11S is not in eeprom"
echo
echo

#mtm:2076-524
#0x31 0x38 0x31 0x35
#0x4C 0x30 0x32
execcmcipmicmd 0x00 0x2F 0x60 0x32 0x30 0x37 0x36 
execcmcipmicmd 0x00 0x2F 0x64 0x35 0x32 0x34
echo "write mtm:2076-524"
echo
echo

#version:001                                                                          
execcmcipmicmd 0x00 0x2B 0x24 0x00 0x01
echo "write version:001"

#partnumber:85y5896                                                                          
execcmcipmicmd 0x00 0x2F 0x56 0x38 0x35 0x59 0x35 0x38 0x39 0x36
echo "write partnumber:85y5896"
                                                                          
#product_sn:S9Y9E6Q																		  
execcmcipmicmd 0x00 0x2F 0x67 0x53 0x39 0x59 0x39 0x45 0x36 0x51
echo "write product_sn:S9Y9E6Q"

#vpd_mid_latest_cluster_id_e	00000200640105e2:                                                                         
execcmcipmicmd 0x00 0x2F 0xA4 0x00 0x00 0x02 0x00 0x64 0x01 0x05 0xe2
echo "write latest_cluster_id:00000200640105e2"
                                                                          
#vpd_mid_next_cluster_id_e	00000200642105e2
execcmcipmicmd 0x00 0x2F 0xAC 0x00 0x00 0x02 0x00 0x64 0x21 0x05 0xe2
echo "write mid_next_cluster_id:00000200642105e2"

#vpd_mid_node1_wwnn_e	5005076801008900
#vpd_mid_node2_wwnn_e	5005076801008901                                                                          
execcmcipmicmd 0x00 0x2F 0xC0 0x50 0x05 0x07 0x68 0x01 0x00 0x89 0x00
execcmcipmicmd 0x00 0x2F 0xC8 0x50 0x05 0x07 0x68 0x01 0x00 0x89 0x01
echo "write node1/2_wwnn:5005076801008900/5005076801008901"
echo
echo

#vpd_mid_node1_SAT_ipv4_address_e	192.168.070.121
execcmcipmicmd 0x00 0x2F 0xE8 0xC0 0xA8 0x46 0x79
echo "write node1_SAT_ipv4_address:192.168.070.121"
                                                                          
#vpd_mid_node1_SAT_ipv6_address_e	000000000000000000000000000000000000000
execcmcipmicmd 0x00 0x2F 0xEC 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
echo "write node1_SAT_ipv6_address:000000000000000000000000000000000000000"
                                                                          
#vpd_mid_node1_SAT_ipv6_prefix_e 000
execcmcipmicmd 0x00 0x2F 0xFC 0x00
echo "write node1_SAT_ipv6_prefix:000"
                                                                          
#vpd_mid_node1_SAT_ipv4_subnet_e	255.255.255.000
#vpd_mid_node1_SAT_ipv4_gateway_e	192.168.070.001
execcmcipmicmd 0x00 0x30 0x00 0xFF 0xFF 0xFF 0x00
execcmcipmicmd 0x00 0x30 0x04 0xC0 0xA8 0x46 0x01
echo "write node1_SAT_ipv4_subnet/gateway:255.255.255.000/192.168.070.001"
echo
echo
                                                                          
#vpd_mid_node1_SAT_ipv6_gateway_e	000000000000000000000000000000000000000
execcmcipmicmd 0x00 0x30 0x08 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 
echo "write node1_SAT_ipv6_gateway:000000000000000000000000000000000000000"
                                                                          
#vpd_mid_node2_SAT_ipv4_address_e	192.168.070.122:
execcmcipmicmd 0x00 0x30 0x28 0xC0 0xA8 0x46 0x7A
echo "write node2_SAT_ipv4_address:192.168.070.122"
                                                                          
#vpd_mid_node2_SAT_ipv6_address_e	000000000000000000000000000000000000000:
execcmcipmicmd 0x00 0x30 0x2C 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
echo "write node2_SAT_ipv6_address:000000000000000000000000000000000000000"
                                                                          
#vpd_mid_node2_SAT_ipv6_prefix_e	000:
execcmcipmicmd 0x00 0x30 0x3C 0x00
echo "write node2_SAT_ipv6_prefix:000"
                                                                          
#vpd_mid_node2_SAT_ipv4_subnet_e	255.255.255.000
execcmcipmicmd 0x00 0x30 0x40 0xFF 0xFF 0xFF 0x00
echo "write node2_SAT_ipv4_subnet:255.255.255.000"
                                                                          
#vpd_mid_node2_SAT_ipv4_gateway_e	192.168.070.001
execcmcipmicmd 0x00 0x30 0x44 0xC0 0xA8 0x46 0x01
echo "write node2_SAT_ipv4_gateway:192.168.070.001"
                                                                          
#vpd_mid_node2_SAT_ipv6_gateway_e	000000000000000000000000000000000000000
execcmcipmicmd 0x00 0x30 0x48 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
echo "write node2_SAT_ipv6_gateway:000000000000000000000000000000000000000"
                                                                          
#vpd_mid_node1_original_wwnn_e	0000000000000000
execcmcipmicmd 0x00 0x30 0x60 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
echo "write node1_original_wwnn:0000000000000000"
                                                                          
#vpd_mid_node2_original_wwnn_e	0000000000000000
execcmcipmicmd 0x00 0x30 0x68 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
echo "write node2_original_wwnn:0000000000000000"


#vpd_can_fru_part_number_e	
#85y6116
#ipmitool raw 0x06 0x52 0x09 0xAC 0x00 0X2B 0x93 0x38 0x35 0x79 0x36 0x31 0x31 0x36

#vpd_can_fru_identity_e
#11S 85Y6112 YHU999 00P5E3
#ipmitool raw 0x06 0x52 0x09 0xAC 0x00 0X2B 0x80 0x38 0x35 0x59 0x36 0x31 0x31 0x32
#ipmitool raw 0x06 0x52 0x09 0xAC 0x00 0X2B 0x87 0x59 0x48 0x55 0x39 0x39 0x39
#ipmitool raw 0x06 0x52 0x09 0xAC 0x00 0X2B 0x8D 0x30 0x30 0x50 0x35 0x45 0x33

if [ $write_ok = 1 ]; then
    echo "write midplane vpd OK"
else
    echo "write midplane vpd fail"
fi



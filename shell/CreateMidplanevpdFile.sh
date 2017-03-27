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
        #echo "cmc${i}_eth1_ip:"${ipaddr[$i]}
        readcmd="timeout -k1 1 ipmitool -H ${ipaddr[$i]} -U admin -P admin raw 0x30 0x23"
        readresult=$(${readcmd})

        cmd_rc=$?
        [ ${cmd_rc} -eq 0 ] || echo "check cmc${i} is master fail,cmd_rc:${cmd_rc}(124:timeout,127:cmd not exist)"

        #echo "cmc${i} is:"${readresult}"(1:master,0:slave)"
        if [ $((${readresult})) = 1 ]; then
            masterCMCip=${ipaddr[$i]}
            return 0
        fi
        i=$(($i+1))
    done

    echo "can't get master cmc ip"
    return 1
}

function execcmcipmicmd()
{
    getmasterCMCip
    cmd_rc=$?
    [ ${cmd_rc} -eq 0 ] || (echo "get master cmc ip fail,cmd_rc is ${cmd_rc}";exit)
                                                                                      #BUS  Addr cnt
    readcmd="timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0"
    paraindex=1

    #use paramaters of the function to build read command
    while [ $(($paraindex)) -le $(($#-1)) ]
    do
        readcmd="${readcmd} ${!paraindex}"
        paraindex=$(($paraindex+1))
    done

    filepath="/data/midplanevpdcache/ReadMidplaneVPDcache_${!paraindex}"
    #echo "${readcmd} >${filepath}" #todo delete this when release

    #execute command and check whether execute successfully.
    ${readcmd} >${filepath}
    cmd_rc=$?
    [ ${cmd_rc} -eq 0 ] || (echo "command exec fail,cmd:${readcmd} >${filepath},cmd_rc:${cmd_rc}"; exit ${cmd_rc})
}

#script start exec from here
masterCMCip=192.168.200.42

vpdfield=( "0x04 0x2f 0x60 01"  #mtm part 1
"0x03 0x2f 0x64 75" #mtm part 2
"0x07 0x2f 0x67 02" #product_sn
"0x07 0x2f 0x40 71" #fru id part2
"0x06 0x2f 0x47 72" #fru id part3
"0x06 0x2f 0x4d 73" #fru id part4
"0x07 0x2f 0x56 03" #fru_part_number
"0x08 0x2f 0xc0 17" #node1_wwnn
"0x08 0x2f 0xc8 18" #node2_wwnn
"0x08 0x30 0x60 59" #node1_original_wwnn
"0x08 0x30 0x68 60" #node2_original_wwnn
"0x08 0x2f 0xac 20" #next cluster id
"0x08 0x2f 0xa4 19" #latest_cluster_id
"0x04 0x2f 0xe8 05" #node1_SAT_ipv4_address
"0x04 0x30 0x00 07" #node1_SAT_ipv4_subnet
"0x04 0x30 0x04 09" #node1_SAT_ipv4_gateway
"0x10 0x2f 0xec 11" #node1_SAT_ipv6_address
"0x01 0x2f 0xfc 13" #node1_SAT_ipv6_prefix
"0x10 0x30 0x08 15" #node1_SAT_ipv6_gateway
"0x04 0x30 0x28 06" #node2_SAT_ipv4_address
"0x04 0x30 0x40 08" #node2_SAT_ipv4_subnet
"0x04 0x30 0x44 10" #node2_SAT_ipv4_gateway
"0x10 0x30 0x2c 12" #node2_SAT_ipv6_address
"0x01 0x30 0x3c 14" #node2_SAT_ipv6_prefix
"0x10 0x30 0x48 16" ) #node2_SAT_ipv6_gateway

arr_mem_cnt=${#vpdfield[@]}
arr_index=0

rm -rf /data/midplanevpdcache
cmd_rc=$?
[ ${cmd_rc} -eq 0 ] || (echo "command exec fail,cmd:rm -rf /data/midplanevpdcache,cmd_rc:${cmd_rc}"; exit ${cmd_rc})

mkdir /data/midplanevpdcache
cmd_rc=$?
[ ${cmd_rc} -eq 0 ] || (echo "command exec fail,cmd:mkdir /data/midplanevpdcache,cmd_rc:${cmd_rc}"; exit ${cmd_rc})

while [ $((${arr_index})) -lt $((${arr_mem_cnt})) ]
do
    execcmcipmicmd ${vpdfield[$arr_index]}
    [ $? -eq 0 ] || exit
    arr_index=$(($arr_index+1))
done
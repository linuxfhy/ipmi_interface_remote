#!/bin/bash
#ipmitool cmnd case:
#                                                           BUS  Addr cnt off_h off_l data....
#ipmitool -H 192.168.200.42 -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x00 0x2B 0x00 

AWKCMD=awk
LSCMD=ls
trcfile="/dumps/scrumtest.trc"
valid_cmc_ip=192.168.200.42

function log()
{
    echo "[$(date -d today +"%Y-%m-%d %H:%M:%S")]" $* >>${trcfile}
}

function get_valid_cmc_ip()
{
    ip=$(ipmitool raw 0x30 0x14)
    array=($ip)
    i=0
    ipaddr[2]=0
    
    for((i=0;i<2;i++))
    do
        ipaddr[$i]="$((16#${array[4+$((8*$i))]})).$((16#${array[5+$((8*$i))]})).$((16#${array[6+$((8*$i))]})).$((16#${array[7+$((8*$i))]}))"
        #log "cmc${i}_eth1_ip:"${ipaddr[$i]}
        readcmd="timeout -k1 1 ipmitool -H ${ipaddr[$i]} -U admin -P admin raw 0x30 0x23"
        readresult=$(${readcmd})
        
        cmd_rc=$(($?))
        if [ ${cmd_rc} != 0 ]; then
            log "check cmc${i} is master fail,cmd_rc:${cmd_rc}(124:timeout,127:cmd not exist)"
            continue
        fi
        
        #log "cmc${i} is:"${readresult}"(1:master,0:slave)"        
        valid_cmc_ip=${ipaddr[$i]}
        return 0
    done
    
    log "can't get master cmc ip"
    return 1
}

function execcmcipmicmd()
{
    get_valid_cmc_ip
    cmd_rc=$(($?))
    if [ ${cmd_rc} != 0 ]; then
        log "get master cmc ip fail,cmd_rc is ${cmd_rc}"
        exit
    fi
                                                                                       #BUS  Addr cnt
    writecmd="timeout -k1 1 ipmitool -H ${valid_cmc_ip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x00"
    paraindex=2
    
    #use paramaters of the function to build wirte command
    while [ $(($paraindex)) -le $# ]    
    do
        writecmd="${writecmd} ${!paraindex}"
        paraindex=$(($paraindex+1))
    done
    
    #execute command and check whether execute successfully.
    ${writecmd} >null
    wirtecmd_rc=$(($?))
    if [ ${wirtecmd_rc} != 0 ]; then
        log "command exec fail,cmd_W:${writecmd},cmd_rc:${wirtecmd_rc}"
        exit
    fi
    
    log "cmd_W:${writecmd}"    
    
    #read data and check weather it equal to write-data
    readcmd="timeout -k1 1 ipmitool -H ${valid_cmc_ip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0"
    readcnt=$(($#-3))
    readcmd="${readcmd} 0x$(printf %.2x $readcnt) $2 $3"
    log "cmd_R:${readcmd}"
    
    readresult=$(${readcmd})
    log "read data is"${readresult}
    
    array=($readresult)
    
    i=0
    while [ $(($i)) -lt $readcnt ]    
    do
        j=$(($i+4))
        if [ $((16#${array[$i]})) != $((${!j})) ]; then
            write_ok=0
            log "read/write data inconsistent:index($i),writedata:$((${!j})),readdata:$((16#${array[$i]}))"
            exit
        fi
        i=$(($i+1))
    done
}




#script start exec from here
write_ok=1
valid_cmc_ip=192.168.200.42

if [ ! -f ${trcfile} ]
then
    touch ${trcfile}
else
    typeset -i SZ
    SZ=$(${LSCMD} -s ${trcfile} | ${AWKCMD} -F " " '{print $1}')
    SZ=${SZ}*1024
    if [ $SZ -gt 163840 ]
    then
        tail --bytes=163840 ${trcfile} >/tmp/$$ 2>/dev/null
        mv -f /tmp/$$ ${trcfile} 2>/dev/null
    fi
fi

log "============Begin exec script $0 at $(date)============" >>${trcfile}

l=$(($RANDOM%10))
m=$(($RANDOM%10))
n=$(($RANDOM%10))

#fru_identify:
#11S 85Y5962 YHU999 4G0284
#0x31 0x31 0x53 
#0x38 0x35 0x59 0x35 0x39 0x36 0x32 
#0x59 0x48 0x55 0x39 0x39 0x39 
#0x34 0x47 0x30 0x3$l 0x3$m 0x3$n
               #cnt of_h of_l data...
execcmcipmicmd 0x00 0x2F 0x40 0x38 0x35 0x59 0x35 0x39 0x36 0x32 
execcmcipmicmd 0x00 0x2F 0x47 0x59 0x48 0x55 0x39 0x39 0x39 
execcmcipmicmd 0x00 0x2F 0x4D 0x34 0x47 0x30 0x3$l 0x3$m 0x3$n
log "write fru_identify:11S85Y5962YHU9994G0$l$m$n, 11S is not in eeprom"



cpu_cnt=$(cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l)
#mtm:1815-L0${cpu_cnt}
#0x31 0x38 0x31 0x35
#0x4C 0x30 0x3${cpu_cnt}
execcmcipmicmd 0x00 0x2F 0x60 0x31 0x38 0x31 0x35 
execcmcipmicmd 0x00 0x2F 0x64 0x4C 0x30 0x3${cpu_cnt}
log "write mtm:1815-L0${cpu_cnt}"



#vpd_mid_version_e:001                                                                          
execcmcipmicmd 0x00 0x2B 0x24 0x00 0x01
log "write vpd_mid_version_e:001"

#vpd_mid_fru_part_number_e:85y5896
execcmcipmicmd 0x00 0x2F 0x56 0x38 0x35 0x59 0x35 0x38 0x39 0x36
log "write vpd_mid_fru_part_number_e:85y5896"


#product_sn:S9Y9$l$m$n                                                                          
execcmcipmicmd 0x00 0x2F 0x67 0x53 0x39 0x59 0x39 0x3$l 0x3$m 0x3$n
log "random l,m,n is $l,$m,$n"
log "write product_sn:S9Y9$l$m$n"

#vpd_mid_latest_cluster_id_e    0000000000000000:                                                                         
execcmcipmicmd 0x00 0x2F 0xA4 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
log "write latest_cluster_id:0000000000000000"
                                                                          
#vpd_mid_next_cluster_id_e    00000200642105e2
execcmcipmicmd 0x00 0x2F 0xAC 0x00 0x00 0x02 0x00 0x64 0x21 0x05 0xe2
log "write mid_next_cluster_id:00000200642105e2"

#vpd_mid_node1_wwnn_e    56c92bf80100${l}${m}${n}0
#vpd_mid_node2_wwnn_e    56c92bf80100${l}${m}${n}1
execcmcipmicmd 0x00 0x2F 0xC0 0x56 0xc9 0x2b 0xf8 0x01 0x00 0x${l}${m} 0x${n}0
execcmcipmicmd 0x00 0x2F 0xC8 0x56 0xc9 0x2b 0xf8 0x01 0x00 0x${l}${m} 0x${n}1
log "write node1/2_wwnn:56c92bf80100${l}${m}${n}0/56c92bf80100${l}${m}${n}1"



#vpd_mid_node1_SAT_ipv4_address_e    192.168.001.100
execcmcipmicmd 0x00 0x2F 0xE8 0xC0 0xA8 0x01 0x64
log "write node1_SAT_ipv4_address:192.168.001.100"
                                                                          
#vpd_mid_node1_SAT_ipv6_address_e    000000000000000000000000000000000000000
execcmcipmicmd 0x00 0x2F 0xEC 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
log "write node1_SAT_ipv6_address:000000000000000000000000000000000000000"
                                                                          
#vpd_mid_node1_SAT_ipv6_prefix_e 000
execcmcipmicmd 0x00 0x2F 0xFC 0x00
log "write node1_SAT_ipv6_prefix:000"
                                                                          
#vpd_mid_node1_SAT_ipv4_subnet_e    255.255.255.000
#vpd_mid_node1_SAT_ipv4_gateway_e    192.168.001.001
execcmcipmicmd 0x00 0x30 0x00 0xFF 0xFF 0xFF 0x00
execcmcipmicmd 0x00 0x30 0x04 0xC0 0xA8 0x01 0x01
log "write node1_SAT_ipv4_subnet/gateway:255.255.255.000/192.168.001.001"


                                                                          
#vpd_mid_node1_SAT_ipv6_gateway_e    000000000000000000000000000000000000000
execcmcipmicmd 0x00 0x30 0x08 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 
log "write node1_SAT_ipv6_gateway:000000000000000000000000000000000000000"
                                                                          
#vpd_mid_node2_SAT_ipv4_address_e    192.168.001.102:
execcmcipmicmd 0x00 0x30 0x28 0xC0 0xA8 0x01 0x66
log "write node2_SAT_ipv4_address:192.168.001.102"
                                                                          
#vpd_mid_node2_SAT_ipv6_address_e    000000000000000000000000000000000000000:
execcmcipmicmd 0x00 0x30 0x2C 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
log "write node2_SAT_ipv6_address:000000000000000000000000000000000000000"
                                                                          
#vpd_mid_node2_SAT_ipv6_prefix_e    000:
execcmcipmicmd 0x00 0x30 0x3C 0x00
log "write node2_SAT_ipv6_prefix:000"
                                                                          
#vpd_mid_node2_SAT_ipv4_subnet_e    255.255.255.000
execcmcipmicmd 0x00 0x30 0x40 0xFF 0xFF 0xFF 0x00
log "write node2_SAT_ipv4_subnet:255.255.255.000"
                                                                          
#vpd_mid_node2_SAT_ipv4_gateway_e    192.168.001.001
execcmcipmicmd 0x00 0x30 0x44 0xC0 0xA8 0x01 0x01
log "write node2_SAT_ipv4_gateway:192.168.001.001"
                                                                          
#vpd_mid_node2_SAT_ipv6_gateway_e    000000000000000000000000000000000000000
execcmcipmicmd 0x00 0x30 0x48 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
log "write node2_SAT_ipv6_gateway:000000000000000000000000000000000000000"
                                                                          
#vpd_mid_node1_original_wwnn_e    0000000000000000
execcmcipmicmd 0x00 0x30 0x60 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
log "write node1_original_wwnn:0000000000000000"
                                                                          
#vpd_mid_node2_original_wwnn_e    0000000000000000
execcmcipmicmd 0x00 0x30 0x68 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
log "write node2_original_wwnn:0000000000000000"

if [ $write_ok = 1 ]; then
    log "write midplane vpd OK"
    exit 0
else
    log "write midplane vpd fail"
    exit 1
fi



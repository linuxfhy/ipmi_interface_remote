#!/bin/bash

function write_and_check_vpd()
{
    writecmd="ec_chvpd -w -n $1 -v $2"
    ${writecmd}
    cmd_rc=$?
    [ ${cmd_rc} -eq 0 ] || {
        echo "cmd exec failed,cmd:${writecmd}, cmd_rc:${cmd_rc}"
        return ${cmd_rc}
    }
    
    readcmd="ec_chvpd -r -n $1"	
    readresult=$(${readcmd})
    cmd_rc=$?
    [ ${cmd_rc} -eq 0 ] || {
        echo "cmd exec failed,cmd:${readcmd}, cmd_rc:${cmd_rc}"
        return ${cmd_rc}
    }
   
   #readresult="${readresult}222" #inject error
    echo "w_cmd is ${writecmd}"
    echo "r_cmd is ${readcmd}"
    echo "read result is ${readresult}"
    
    [ ${readresult} != $2 ] && {
    echo "read_write mismatch,read:${readresult},write:$2"
    return 1
    }
    
    return 0
}

function write_and_check_vpd_encap()
{
    write_and_check_vpd $1 $2
    cmd_rc=$?
    [ ${cmd_rc} -eq 0 ] || {
        echo "cmd exec failed,para1:$1,para2:$2"
        return ${cmd_rc}
    }
}


l=$(($RANDOM%10))
m=$(($RANDOM%10))
n=$(($RANDOM%10))
write_ok=1

cpu_cnt=$(cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l)

vpdfield=( "vpd_mid_product_mtm_e 1815-L0${cpu_cnt}"
"vpd_mid_fru_identity_e 11S85Y5962YHU9994G0$l$m$n"
"vpd_mid_version_e 001"
"vpd_mid_fru_part_number_e 85y5896"
"vpd_mid_product_sn_e S9Y9$l$m$n"
"vpd_mid_latest_cluster_id_e 0000000000000000"
"vpd_mid_next_cluster_id_e 00000200642105e2"
"vpd_mid_node1_wwnn_e 56c92bf80100${l}${m}${n}0"
"vpd_mid_node2_wwnn_e 56c92bf80100${l}${m}${n}1"
"vpd_mid_node1_SAT_ipv4_address_e 192.168.001.100"
"vpd_mid_node1_SAT_ipv6_address_e 000000000000000000000000000000000000000"
"vpd_mid_node1_SAT_ipv6_prefix_e 000"
"vpd_mid_node1_SAT_ipv4_subnet_e 255.255.255.000"
"vpd_mid_node1_SAT_ipv4_gateway_e 192.168.001.001"
"vpd_mid_node1_SAT_ipv6_gateway_e 000000000000000000000000000000000000000"
"vpd_mid_node2_SAT_ipv4_address_e 192.168.001.102"
"vpd_mid_node2_SAT_ipv6_address_e 000000000000000000000000000000000000000"
"vpd_mid_node2_SAT_ipv6_prefix_e 000"
"vpd_mid_node2_SAT_ipv4_subnet_e 255.255.255.000"
"vpd_mid_node2_SAT_ipv4_gateway_e 192.168.001.001"
"vpd_mid_node2_SAT_ipv6_gateway_e 000000000000000000000000000000000000000"
"vpd_mid_node1_original_wwnn_e 0000000000000000"
"vpd_mid_node2_original_wwnn_e 0000000000000000" )
arr_mem_cnt=${#vpdfield[@]}
arr_index=0

while [ $((${arr_index})) -lt $((${arr_mem_cnt})) ]
do
    write_and_check_vpd_encap ${vpdfield[$arr_index]}
    #log ${vpdfield[$arr_index]}
    [ $? -eq 0 ] || {
        write_ok=0
        break
    }
    arr_index=$(($arr_index+1))
done

if [ $write_ok = 1 ]; then
    echo "write midplane vpd OK"
else
    echo "write midplane vpd fail"
fi

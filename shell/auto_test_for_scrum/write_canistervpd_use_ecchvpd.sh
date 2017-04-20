#!/bin/bash

function write_and_check_vpd()
{
    writecmd="ec_chvpd -w -c -n $1 -v $2"
    ${writecmd}
    cmd_rc=$?
    [ ${cmd_rc} -eq 0 ] || {
        echo "cmd exec failed,cmd:${writecmd}, cmd_rc:${cmd_rc}"
        return ${cmd_rc}
    }
    
    readcmd="ec_chvpd -r -c -n $1"	
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

vpdfield=( "vpd_can_fru_part_number_e 85y6116"
"vpd_can_fru_identity_e 11S85Y6112YHU99900P5E3" )
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
    echo "write canister vpd OK"
    exit 0
else
    echo "write canister vpd fail"
    exit 1
fi

#!/bin/bash

AWKCMD=awk
LSCMD=ls
trcfile="/dumps/scrumtest.trc"
g_para_1=$1

function log()
{
    echo "[$(date -d today +"%Y-%m-%d %H:%M:%S")]" $* >>${trcfile}
}

function write_and_check_vpd()
{
    writecmd="/compass/ec_chvpd -w -c -n $1 -v $2"
    ${writecmd}
    cmd_rc=$?
    [ ${cmd_rc} -eq 0 ] || {
        log "cmd exec failed,cmd:${writecmd}, cmd_rc:${cmd_rc}"
        return ${cmd_rc}
    }
    
    readcmd="/compass/ec_chvpd -r -c -n $1"
    readresult=$(${readcmd})
    cmd_rc=$?
    [ ${cmd_rc} -eq 0 ] || {
        log "cmd exec failed,cmd:${readcmd}, cmd_rc:${cmd_rc}"
        return ${cmd_rc}
    }
   
   #readresult="${readresult}222" #inject error
    #log "w_cmd is ${writecmd}"
    #log "r_cmd is ${readcmd}"
    #log "read result is ${readresult}"
    
    write_data=$2
    if [[ $1 =~ "vpd_can_version_e" ]]
    then
        write_data="0${write_data}"
    fi

    [ ${readresult} != ${write_data} ] && {
        log "read_write mismatch,read:${readresult},write:${write_data}"
        return 1
    }

    return 0
}

function write_and_check_vpd_encap()
{
    write_and_check_vpd $1 $2
    cmd_rc=$?
    [ ${cmd_rc} -eq 0 ] || {
        log "cmd exec failed,para1:$1,para2:$2"
        return ${cmd_rc}
    }
}

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
write_ok=1

cpu_cnt=$(cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l)

vpdfield=( "vpd_can_fru_part_number_e 85y6${l}${m}${n}"
"vpd_can_version_e 504"
#"vpd_can_model_type_e 00000000000000000000000000000000"
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

#上一次循环写入每一项相当于初始化，第二次写入每一项时需要判断对其它项有没有影响
if [[ ${g_para_1} =~ "w_affec" ]]; then
    arr_index=0
    log "check whether other vpd fields will be changed when we write one field"
    while [ $((${arr_index})) -lt $((${arr_mem_cnt})) ]; do
        write_and_check_vpd_encap ${vpdfield[$arr_index]}
        #log ${vpdfield[$arr_index]}
        [ $? -eq 0 ] || {
            write_ok=0
            break
        }

        arr_index_j=0
        while [ $((${arr_index_j})) -lt $((${arr_mem_cnt})) ]; do
            log "arr_index_j is ${arr_index_j}, arr_index is ${arr_index} before continue"
            if [ "${arr_index_j}" = "${arr_index}" ]; then
                arr_index_j=$(($arr_index_j+1))
                continue
            fi
            tmp_arr=(${vpdfield[$arr_index_j]})
            readcmd="/compass/ec_chvpd -c -r -n ${tmp_arr[0]}"
            readresult=$(${readcmd})
            cmd_rc=$?
            [ ${cmd_rc} -eq 0 ] || {
                log "cmd exec failed,cmd:${readcmd}, cmd_rc:${cmd_rc}"
                exit ${cmd_rc}
            }
            log "read_write compare,read:${readresult},write:${tmp_arr[1]}"
            write_data=${tmp_arr[1]}
            if [[ ${tmp_arr[0]} =~ "vpd_can_version_e" ]]
            then
                write_data="0${write_data}"
            fi

            [ ${readresult} != ${write_data} ] && {
                log "read_write mismatch,read:${readresult},write:${tmp_arr[1]}"
                exit 1
            }
            arr_index_j=$(($arr_index_j+1))
        done

        arr_index=$(($arr_index+1))
    done
fi

if [ $write_ok = 1 ]; then
    log "write canister vpd OK"
    exit 0
else
    log "write canister vpd fail"
    exit 1
fi

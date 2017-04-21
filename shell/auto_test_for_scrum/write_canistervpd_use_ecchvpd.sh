#!/bin/bash

AWKCMD=awk
LSCMD=ls
trcfile="/dumps/scrumtest.trc"

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
    log "w_cmd is ${writecmd}"
    log "r_cmd is ${readcmd}"
    log "read result is ${readresult}"
    
    [ ${readresult} != $2 ] && {
    log "read_write mismatch,read:${readresult},write:$2"
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
    log "write canister vpd OK"
    exit 0
else
    log "write canister vpd fail"
    exit 1
fi

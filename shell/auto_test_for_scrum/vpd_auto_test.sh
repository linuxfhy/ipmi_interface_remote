#!/bin/bash

AWKCMD=awk
LSCMD=ls
trcfile="/dumps/scrumtest.trc"

function log()
{
    echo "[$(date -d today +"%Y-%m-%d %H:%M:%S")]" $* >>${trcfile}
}

function remote_exec()
{
    ssh -p 26 ${remote_ip} "$*"
    return $?
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

#script start
log "============Begin exec script $0 at $(date)============" >>${trcfile}
rm -rf /home/vpd_test
mkdir /home/vpd_test
remote_ip=100.2.45.177

#test case_1
{
    log "exec test case 1"
    for((i=0;i<2;i++))
    do
        if [ $i -eq 0 ];then
             cur_node="local"
             log "exec write_midplanevpd_optimized_anyCPUcnt.sh on local node"
             sh write_midplanevpd_optimized_anyCPUcnt.sh
        else
            cur_node="local"
            log "exec write_midplanevpd_optimized_anyCPUcnt.sh on remote node"
            remote_exec "sh /home/root/write_midplanevpd_optimized_anyCPUcnt.sh"
        fi
        [ $? -eq 0 ] || {
            log "exec write_midplanevpd_optimized_anyCPUcnt fail on ${cur_node} node"
            exit 1
        }

        local_can_id=$(cat /dev/canisterid)
        local_cmd="ec_chvpd -sa"
        local_file_path="/home/vpd_test/ec_chvpd_result_${local_can_id}"
        log "exec ec_chvpd -sa on local node"
        ${local_cmd} >${local_file_path}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on local node,cmd_rc is $?,cmd:$0"
            exit 1
        }
        remot_can_id=$(remote_exec "cat /dev/canisterid")
        log "exec ec_chvpd -sa on remote node"
        remote_exec ". /home/debug/test_profile; /compass/ec_chvpd -sa" >/home/vpd_test/ec_chvpd_result_${remot_can_id}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on remote node"
            exit 1
        }
        log "compare ec_chvpd_result_${local_can_id} ec_chvpd_result_${remot_can_id}"
        tmp_cmd="diff /home/vpd_test/ec_chvpd_result_${local_can_id} /home/vpd_test/ec_chvpd_result_${remot_can_id}"
        ${tmp_cmd}
        [ $? -eq 0 ] || {
            log "ec_chvpd -sa result diff between local and remote,loop $i"
            exit 1
        }
        log "local/remote ec_chvpd -sa result same"
    done
    log "case 1 pass"
}


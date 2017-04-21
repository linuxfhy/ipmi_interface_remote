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

#test case 1.1
{
    log ">>>>>>test case 1.1 start<<<<<<"
    total_step_case_1_1=8
    cur_step=1
    for((i=0;i<2;i++))
    do
        if [ $i -eq 0 ];then
             cur_node="local"
             log "STEP ${cur_step} of ${total_step_case_1_1}:exec write_midplanevpd_optimized_anyCPUcnt.sh on local node"
             cur_step=$((${cur_step}+1))
             sh write_midplanevpd_optimized_anyCPUcnt.sh
        else
            cur_node="local"
            log "STEP ${cur_step} of ${total_step_case_1_1}:exec write_midplanevpd_optimized_anyCPUcnt.sh on remote node"
            cur_step=$((${cur_step}+1))
            remote_exec "sh /home/root/write_midplanevpd_optimized_anyCPUcnt.sh"
        fi

        [ $? -eq 0 ] || {
            log "exec write_midplanevpd_optimized_anyCPUcnt fail on ${cur_node} node"
            exit 1
        }

        local_can_id=$(cat /dev/canisterid)
        local_cmd="ec_chvpd -sa"
        local_file_path="/home/vpd_test/ec_chvpd_result_${local_can_id}"
        log "STEP ${cur_step} of ${total_step_case_1_1}:exec ec_chvpd -sa on local node"
        cur_step=$((${cur_step}+1))

        ${local_cmd} >${local_file_path}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on local node,cmd_rc is $?,cmd:$0"
            exit 1
        }

        remot_can_id=$(remote_exec "cat /dev/canisterid")
        log "STEP ${cur_step} of ${total_step_case_1_1}:exec ec_chvpd -sa on remote node"
        cur_step=$((${cur_step}+1))
        remote_exec ". /home/debug/test_profile; /compass/ec_chvpd -sa" >/home/vpd_test/ec_chvpd_result_${remot_can_id}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on remote node"
            exit 1
        }

        log "STEP ${cur_step} of ${total_step_case_1_1}:compare ec_chvpd_result_${local_can_id} ec_chvpd_result_${remot_can_id}"
        tmp_cmd="diff /home/vpd_test/ec_chvpd_result_${local_can_id} /home/vpd_test/ec_chvpd_result_${remot_can_id}"
        ${tmp_cmd}
        [ $? -eq 0 ] || {
            log "ec_chvpd -sa result diff between local and remote,loop $i"
            exit 1
        }
        log "             local/remote ec_chvpd -sa result same"
        [ $i -eq 0 ] && {
            cur_step=$((${cur_step}+1))
        }
    done
    log ">>>>>>test case 1.1 pass<<<<<<"
}

#test case 1.2
{
    log ">>>>>>test case 1.2 start<<<<<<"
    total_step_case_1_2=8
    cur_step=1
    for((i=0;i<2;i++))
    do
        if [ $i -eq 0 ];then
             cur_node="local"
             log "STEP ${cur_step} of ${total_step_case_1_2}:exec write_midplanevpd_use_ecchvpd.sh on local node"
             cur_step=$((${cur_step}+1))
             sh write_midplanevpd_use_ecchvpd.sh
        else
            cur_node="remote"
            log "STEP ${cur_step} of ${total_step_case_1_2}:exec write_midplanevpd_use_ecchvpd.sh on remote node"
            cur_step=$((${cur_step}+1))
            remote_exec ". /home/debug/test_profile; sh /home/root/write_midplanevpd_use_ecchvpd.sh"
        fi

        [ $? -eq 0 ] || {
            log "exec write_midplanevpd_use_ecchvpd fail on ${cur_node} node"
            exit 1
        }

        local_can_id=$(cat /dev/canisterid)
        local_cmd="ec_chvpd -sa"
        local_file_path="/home/vpd_test/ec_chvpd_result_${local_can_id}"
        log "STEP ${cur_step} of ${total_step_case_1_2}:exec ec_chvpd -sa on local node"
        cur_step=$((${cur_step}+1))

        ${local_cmd} >${local_file_path}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on local node,cmd_rc is $?,cmd:$0"
            exit 1
        }

        remot_can_id=$(remote_exec "cat /dev/canisterid")
        log "STEP ${cur_step} of ${total_step_case_1_2}:exec ec_chvpd -sa on remote node"
        cur_step=$((${cur_step}+1))
        remote_exec ". /home/debug/test_profile; /compass/ec_chvpd -sa" >/home/vpd_test/ec_chvpd_result_${remot_can_id}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on remote node"
            exit 1
        }

        log "STEP ${cur_step} of ${total_step_case_1_2}:compare ec_chvpd_result_${local_can_id} ec_chvpd_result_${remot_can_id}"
        tmp_cmd="diff /home/vpd_test/ec_chvpd_result_${local_can_id} /home/vpd_test/ec_chvpd_result_${remot_can_id}"
        ${tmp_cmd}
        [ $? -eq 0 ] || {
            log "ec_chvpd -sa result diff between local and remote,loop $i"
            exit 1
        }
        log "             local/remote ec_chvpd -sa result same"
        [ $i -eq 0 ] && {
            cur_step=$((${cur_step}+1))
        }
    done
    log ">>>>>>test case 1.2 pass<<<<<<"
}

#test case 1.3
{
    log ">>>>>>test case 1.3 start<<<<<<"
    total_step_case_1_3=8
    cur_step=1
    for((i=0;i<2;i++))
    do
        if [ $i -eq 0 ];then
             cur_node="local"
             log "STEP ${cur_step} of ${total_step_case_1_3}:exec write_canistervpd_optimized.sh on local node"
             cur_step=$((${cur_step}+1))
             sh write_canistervpd_optimized.sh
        else
            cur_node="local"
            log "STEP ${cur_step} of ${total_step_case_1_3}:exec write_canistervpd_optimized.sh on remote node"
            cur_step=$((${cur_step}+1))
            remote_exec "sh /home/root/write_canistervpd_optimized.sh"
        fi

        [ $? -eq 0 ] || {
            log "executing write_can_vpd use ipmi fail on ${cur_node} node"
            exit 1
        }

        local_can_id=$(cat /dev/canisterid)
        local_cmd="ec_chvpd -sa"
        local_file_path="/home/vpd_test/ec_chvpd_result_${local_can_id}"
        log "STEP ${cur_step} of ${total_step_case_1_3}:exec ec_chvpd -sa on local node"
        cur_step=$((${cur_step}+1))

        ${local_cmd} >${local_file_path}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on local node,cmd_rc is $?,cmd:$0"
            exit 1
        }

        remot_can_id=$(remote_exec "cat /dev/canisterid")
        log "STEP ${cur_step} of ${total_step_case_1_3}:exec ec_chvpd -sa on remote node"
        cur_step=$((${cur_step}+1))
        remote_exec ". /home/debug/test_profile; /compass/ec_chvpd -sa" >/home/vpd_test/ec_chvpd_result_${remot_can_id}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on remote node"
            exit 1
        }

        log "STEP ${cur_step} of ${total_step_case_1_3}:compare ec_chvpd_result_${local_can_id} ec_chvpd_result_${remot_can_id}"
        tmp_cmd="diff /home/vpd_test/ec_chvpd_result_${local_can_id} /home/vpd_test/ec_chvpd_result_${remot_can_id}"
        ${tmp_cmd}
        [ $? -eq 1 ] || {
            log "ec_chvpd -sa result same between local and remote node,shoulde be different,loop $i"
            exit 1
        }
        log "             local/remote ec_chvpd -sa result different(should be different)"
        [ $i -eq 0 ] && {
            cur_step=$((${cur_step}+1))
        }
    done
    log ">>>>>>test case 1.3 pass<<<<<<"
}

#test case 1.4
{
    log ">>>>>>test case 1.4 start<<<<<<"
    total_step_case4=8
    cur_step=1
    for((i=0;i<2;i++))
    do
        if [ $i -eq 0 ];then
             cur_node="local"
             log "STEP ${cur_step} of ${total_step_case4}:exec write_canistervpd_use_ecchvpd.sh on local node"
             cur_step=$((${cur_step}+1))
             sh write_canistervpd_use_ecchvpd.sh
        else
            cur_node="local"
            log "STEP ${cur_step} of ${total_step_case4}:exec write_canistervpd_use_ecchvpd.sh on remote node"
            cur_step=$((${cur_step}+1))
            remote_exec "sh /home/root/write_canistervpd_use_ecchvpd.sh"
        fi

        [ $? -eq 0 ] || {
            log "exec write_canistervpd_use_ecchvpd.sh fail on ${cur_node} node"
            exit 1
        }

        local_can_id=$(cat /dev/canisterid)
        local_cmd="ec_chvpd -sa"
        local_file_path="/home/vpd_test/ec_chvpd_result_${local_can_id}"
        log "STEP ${cur_step} of ${total_step_case4}:exec ec_chvpd -sa on local node"
        cur_step=$((${cur_step}+1))

        ${local_cmd} >${local_file_path}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on local node,cmd_rc is $?,cmd:$0"
            exit 1
        }

        remot_can_id=$(remote_exec "cat /dev/canisterid")
        log "STEP ${cur_step} of ${total_step_case4}:exec ec_chvpd -sa on remote node"
        cur_step=$((${cur_step}+1))
        remote_exec ". /home/debug/test_profile; /compass/ec_chvpd -sa" >/home/vpd_test/ec_chvpd_result_${remot_can_id}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on remote node"
            exit 1
        }

        log "STEP ${cur_step} of ${total_step_case4}:compare ec_chvpd_result_${local_can_id} ec_chvpd_result_${remot_can_id}"
        tmp_cmd="diff /home/vpd_test/ec_chvpd_result_${local_can_id} /home/vpd_test/ec_chvpd_result_${remot_can_id}"
        ${tmp_cmd}
        [ $? -eq 1 ] || {
            log "ec_chvpd -sa result same between local and remote node,shoulde be different,loop $i"
            exit 1
        }
        log "             local/remote ec_chvpd -sa result different(should be different)"
        [ $i -eq 0 ] && {
            cur_step=$((${cur_step}+1))
        }
    done
    log ">>>>>>test case 1.4 pass<<<<<<"
}

#test case 2.1
log ">>>>>>test case 2.1 start<<<<<<"
log "This case is same as 1.2,pass"
log ">>>>>>test case 2.1 pass<<<<<<"
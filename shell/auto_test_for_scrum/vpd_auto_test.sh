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
log "============test loop $1 start============" >>${trcfile}
log "============Begin exec script $0 at $(date)============" >>${trcfile}
#rm -rf /home/vpd_test
#mkdir /home/vpd_test
remote_ip=100.2.45.177

kill_node -f


:<<!
!


#test case 1.1
function test_case_fun_1_1 ()
{
    total_step_case_1_1=8
    cur_step=1
    for((i=0;i<2;i++))
    do
        if [ $i -eq 0 ];then
             cur_node="local"
             log "STEP ${cur_step} of ${total_step_case_1_1}:exec $1 on local node"
             cur_step=$((${cur_step}+1))
             sh $1
        else
            cur_node="local"
            log "STEP ${cur_step} of ${total_step_case_1_1}:exec $1 on remote node"
            cur_step=$((${cur_step}+1))
            remote_exec "sh /home/root/$1"
        fi

        [ $? -eq 0 ] || {
            log "exec $1 fail on ${cur_node} node"
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
    return 0
}

log ">>>>>>test case 1.1 start<<<<<<"
#test_case_fun_1_1 write_midplanevpd_optimized_anyCPUcnt.sh
[ $? -eq 0 ] || exit 1
log ">>>>>>test case 1.1 pass<<<<<<"

#test case 1.2
function test_case_fun_1_2
{
    total_step_case_1_2=8
    cur_step=1
    for((i=0;i<2;i++))
    do
        if [ $i -eq 0 ];then
             cur_node="local"
             log "STEP ${cur_step} of ${total_step_case_1_2}:exec $1 on local node"
             cur_step=$((${cur_step}+1))
             sh $1
        else
            cur_node="remote"
            log "STEP ${cur_step} of ${total_step_case_1_2}:exec $1 on remote node"
            cur_step=$((${cur_step}+1))
            remote_exec ". /home/debug/test_profile; sh /home/root/$1"
        fi

        [ $? -eq 0 ] || {
            log "exec $1 fail on ${cur_node} node"
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
    return 0
}

log ">>>>>>test case 1.2 start<<<<<<"
#test_case_fun_1_2 write_midplanevpd_use_ecchvpd.sh
[ $? -eq 0 ] || exit 1
log ">>>>>>test case 1.2 pass<<<<<<"


#test case 1.3
function test_case_fun_1_3()
{
    total_step_case_1_3=8
    cur_step=1
    for((i=0;i<2;i++))
    do
        if [ $i -eq 0 ];then
             cur_node="local"
             log "STEP ${cur_step} of ${total_step_case_1_3}:exec $1 on local node"
             cur_step=$((${cur_step}+1))
             sh $1
        else
            cur_node="remote"
            log "STEP ${cur_step} of ${total_step_case_1_3}:exec $1 on remote node"
            cur_step=$((${cur_step}+1))
            remote_exec "sh /home/root/$1"
        fi

        [ $? -eq 0 ] || {
            log "executing write_can_vpd use ipmi fail on ${cur_node} node"
            exit 1
        }

        local_can_id=$(cat /dev/canisterid)
        local_cmd="ec_chvpd -c -sa"
        local_file_path="/home/vpd_test/can_vpd_result_${local_can_id}"
        log "STEP ${cur_step} of ${total_step_case_1_3}:exec ec_chvpd -c -sa on local node"
        cur_step=$((${cur_step}+1))

        ${local_cmd} >${local_file_path}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -c -sa fail on local node,cmd_rc is $?,cmd:$0"
            exit 1
        }

        remot_can_id=$(remote_exec "cat /dev/canisterid")
        log "STEP ${cur_step} of ${total_step_case_1_3}:exec ec_chvpd -c -sa on remote node"
        cur_step=$((${cur_step}+1))
        remote_exec ". /home/debug/test_profile; /compass/ec_chvpd -c -sa" >/home/vpd_test/can_vpd_result_${remot_can_id}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -c -sa fail on remote node"
            exit 1
        }

        log "STEP ${cur_step} of ${total_step_case_1_3}:compare can_vpd_result_${local_can_id} can_vpd_result_${remot_can_id}"
        tmp_cmd="diff /home/vpd_test/can_vpd_result_${local_can_id} /home/vpd_test/can_vpd_result_${remot_can_id}"
        ${tmp_cmd}
        [ $? -eq 1 ] || {
            log "ec_chvpd -c -sa result same between local and remote node,shoulde be different,loop $i"
            exit 1
        }
        log "             local/remote ec_chvpd -c -sa result different(should be different)"
        [ $i -eq 0 ] && {
            cur_step=$((${cur_step}+1))
        }
    done
    return 0
}

log ">>>>>>test case 1.3 start<<<<<<"
#test_case_fun_1_3 write_canistervpd_optimized.sh
[ $? -eq 0 ] || exit 1
log ">>>>>>test case 1.3 pass<<<<<<"

#test case 1.4
function test_case_fun_1_4()
{
    total_step_case4=8
    cur_step=1
    for((i=0;i<2;i++))
    do
        if [ $i -eq 0 ];then
             cur_node="local"
             log "STEP ${cur_step} of ${total_step_case4}:exec $1 on local node"
             cur_step=$((${cur_step}+1))
             sh $1
        else
            cur_node="remote"
            log "STEP ${cur_step} of ${total_step_case4}:exec $1 on remote node"
            cur_step=$((${cur_step}+1))
            remote_exec ". /home/debug/test_profile; sh /home/root/$1"
        fi

        [ $? -eq 0 ] || {
            log "exec $1 fail on ${cur_node} node"
            exit 1
        }

        local_can_id=$(cat /dev/canisterid)
        local_cmd="ec_chvpd -c -sa"
        local_file_path="/home/vpd_test/ec_chvpd_can_result_${local_can_id}"
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
        remote_exec ". /home/debug/test_profile; /compass/ec_chvpd -c -sa" >/home/vpd_test/ec_chvpd_can_result_${remot_can_id}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on remote node"
            exit 1
        }

        log "STEP ${cur_step} of ${total_step_case4}:compare ec_chvpd_can_result_${local_can_id} ec_chvpd_can_result_${remot_can_id}"
        tmp_cmd="diff /home/vpd_test/ec_chvpd_can_result_${local_can_id} /home/vpd_test/ec_chvpd_can_result_${remot_can_id}"
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
    return 0
}

log ">>>>>>test case 1.4 start<<<<<<"
#test_case_fun_1_4 write_canistervpd_use_ecchvpd.sh
[ $? -eq 0 ] || exit 1
log ">>>>>>test case 1.4 pass<<<<<<"

#CMC网络正常读取（这里讲CMC0初始化为master）
#test case 2.1
log ">>>>>>test case 2.1 start<<<<<<"
timeout -k1 2 ipmitool -H 192.168.200.42 -U admin -P admin raw 0x30 0x22 0x01
[ $? -eq 0 ] || exit 1
log "This case is same as 1.2,pass"
log ">>>>>>test case 2.1 pass<<<<<<"

#设置IPMI主从命令
#ipmitool -H 192.168.200.42 -U admin -P admin raw 0x30 0x22 0x00/01

#通过主CMC进行刷写，备CMC进行读取
#test case 2.2
log ">>>>>>test case 2.2 start<<<<<<"
#sh write_midplanevpd_use_ecchvpd.sh w_0_r_1
[ $? -eq 0 ] || exit 1
log ">>>>>>test case 2.2 pass<<<<<<"

#刷写一项查看其它项是否有影响
#test case 2.3
log ">>>>>>test case 2.3 start<<<<<<"
#sh write_midplanevpd_use_ecchvpd.sh w_affec
[ $? -eq 0 ] || exit 1
log ">>>>>>test case 2.3 pass<<<<<<"


:<<!
#主备切换后，双控分别刷写，读取对比
#test case 2.2
log ">>>>>>test case 2.2 start<<<<<<"
timeout -k1 2 ipmitool -H 192.168.200.42 -U admin -P admin raw 0x30 0x22 0x00
#test_case_fun_1_2 write_midplanevpd_use_ecchvpd.sh
[ $? -eq 0 ] || exit 1
timeout -k1 2 ipmitool -H 192.168.200.42 -U admin -P admin raw 0x30 0x22 0x01
log ">>>>>>test case 2.2 pass<<<<<<"

#刷写后进行切换主备，双控读取对比
#test case 2.3
function test_case_fun_2_3()
{
    total_step_case_2_3=10
    cur_step=1
    for((i=0;i<2;i++))
    do
        if [ $i -eq 0 ];then
             cur_node="local"
             log "STEP ${cur_step} of ${total_step_case_2_3}:exec $1 on local node"
             cur_step=$((${cur_step}+1))
             sh $1
        else
            cur_node="remote"
            log "STEP ${cur_step} of ${total_step_case_2_3}:exec $1 on remote node"
            cur_step=$((${cur_step}+1))
            remote_exec ". /home/debug/test_profile; sh /home/root/$1"
        fi

        [ $? -eq 0 ] || {
            log "exec $1 fail on ${cur_node} node"
            exit 1
        }

        log "STEP ${cur_step} of ${total_step_case_2_3}:set cmc0 $i(1:master 0:slave)"
        cur_step=$((${cur_step}+1))
        ipmitool -H 192.168.200.42 -U admin -P admin raw 0x30 0x22 0x0$i
        [ $? -eq 0 ] || {
            log "set cmc0 $i(1:master 0:slave) fail"
            exit 1
        }

        local_can_id=$(cat /dev/canisterid)
        local_cmd="ec_chvpd -sa"
        local_file_path="/home/vpd_test/ec_chvpd_result_${local_can_id}"
        log "STEP ${cur_step} of ${total_step_case_2_3}:exec ec_chvpd -sa on local node"
        cur_step=$((${cur_step}+1))

        ${local_cmd} >${local_file_path}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on local node,cmd_rc is $?,cmd:$0"
            exit 1
        }

        remot_can_id=$(remote_exec "cat /dev/canisterid")
        log "STEP ${cur_step} of ${total_step_case_2_3}:exec ec_chvpd -sa on remote node"
        cur_step=$((${cur_step}+1))
        remote_exec ". /home/debug/test_profile; /compass/ec_chvpd -sa" >/home/vpd_test/ec_chvpd_result_${remot_can_id}
        [ $? -eq 1 ] || {
            log "exec ec_chvpd -sa fail on remote node"
            exit 1
        }

        log "STEP ${cur_step} of ${total_step_case_2_3}:compare ec_chvpd_result_${local_can_id} ec_chvpd_result_${remot_can_id}"
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
    return 0
}
log ">>>>>>test case 2.3 start<<<<<<"
#test_case_fun_2_3 write_midplanevpd_optimized_anyCPUcnt.sh
[ $? -eq 0 ] || exit 1
log ">>>>>>test case 2.3 pass<<<<<<"

#模拟CMC0(master)不通
#test case 2.4
log ">>>>>>test case 2.4 start<<<<<<"
ifconfig eth2 down
#test_case_fun_1_1 write_midplanevpd_optimized_anyCPUcnt.sh
[ $? -eq 0 ] || {
    ifconfig eth2 up
    exit 1
}
ifconfig eth2 up
log ">>>>>>test case 2.4 pass<<<<<<"

#模拟CMC1(slave)不通
#test case 2.5
log ">>>>>>test case 2.5 start<<<<<<"
ifconfig eth3 down
#test_case_fun_1_1 write_midplanevpd_optimized_anyCPUcnt.sh
[ $? -eq 0 ] || {
    ifconfig eth3 up
    exit 1
}
ifconfig eth3 up
log ">>>>>>test case 2.5 pass<<<<<<"

log ">>>>>>test case 2.6/2.7 need remove cmc handly, mark as pass<<<<<<"

#读写canister VPD
#test case 3.1/3.1
log ">>>>>>test case 3.1/3.2 start<<<<<<"
log "These two case are same as case 1.3"
log ">>>>>>test case 3.1/3.2 pass<<<<<<"

#正常情况下启动ecmain
#test case 4.1
function test_case_fun_4_1()
{
    start_ok=0
    compass_start
    for((i=0;i<60;i++))
    do
        sainfo lsservicenodes | grep $(/compass/ec_getend | cut -d: -f7) | grep Candidate
        [ $? -eq 0 ] || {
            #log "compass_start hasn't complete,loop $i"
            sleep 2
            continue
        }
        start_ok=1
        break
    done
    [ ${start_ok} -eq 1 ] || {
        log "compass_start fail "
        exit 1
    }

    return 0
}
log ">>>>>>test case 4.1 start<<<<<<"
#test_case_fun_4_1
[ $? -eq 0 ] || {
    exit 1
}
log ">>>>>>test case 4.1 pass<<<<<<"


#注入一次执行命令超时
#test case 6.1
function test_case_fun_6_1()
{
    sh write_midplanevpd_use_ecchvpd_inject_err.sh $1
}
log ">>>>>>test case 6.1 start<<<<<<"
#test_case_fun_6_1 timeout
[ $? -eq 0 ] || {
    exit 1
}
log ">>>>>>test case 6.1 pass <<<<<<"

log ">>>>>>test case 6.2 start<<<<<<"
#test_case_fun_6_1 short
[ $? -eq 0 ] || {
    exit 1
}
log ">>>>>>test case 6.2 pass <<<<<<"
!

log "============test loop $1 end============" >>${trcfile}
exit 0

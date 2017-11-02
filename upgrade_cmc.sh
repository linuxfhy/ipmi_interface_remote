#!/bin/bash
#
# upgrade_cmc.sh - cmc upgrade script for A01, for cmc fault and replacement
#
# start_Copyright_Notice
# end_Copyright_Notice

function decompress_cmcfw
{
    # Now do adapter firmware
    cd /tmp
    rm -rf /tmp/cmcfw
    mkdir -p /tmp/cmcfw
    cd /tmp/cmcfw

    tar -xzOf /compass/00000006 compass/firmwareA01.tgz | tar -xzf -
}

#set -x args
set -x args
#Set the path
PATH=/compass:/compass/bin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH
decompress_cmcfw
export CMCFWDIR=/tmp/cmcfw
needrb=0
source $CMCFWDIR/codever
chmod 777 $CMCFWDIR/Yafuflash_CMC
cmc0_ver=""
cmc1_ver=""
cmc0_cpld_ver=""
cmc1_cpld_ver=""

#if cmc is only or cmc read failed,do not to upgrade and not to report failed
cmconly=0
#if some error happens, do not upgrade but need to tell user our version
notupgrade=0
#use for puting unupgrade component's name
unupgrade_string=()
#use for puting unupgrade component's version
unupgrade_version=()
#use for expect component's version
expect_version=()
#use for remember array postion
pos=0

#imm_service
IMM_CMC="imm_service -read -elmt cmc_version"
IMM_BMC="imm_service -read -elmt canister_version"
#mnet
MNET="mnet"
#bios path
DMIDIR="/sys/class/dmi/id"

#process debug option
declare -A debug_option
debug_option=([bios]="none" [8733]="none" [8796]="none" [cmc]="none" \
	      [cmc_cpld]="none" [bmc]="none" [cpld]="none" [retry_cmc]="none" \
	      [retry_ccpld]="none" [retry_time]="0" [error]="0")
#debug for force upgrade
debug_return="false"

#define max times for retry to get version
retry_max_time=5

# wait reboot
# arg1: sleep time
# arg2: target ip
# arg3: cmc0 or cmc1
function wait_reboot {
	typeset iter=0
	typeset getip=""
	while (( $iter < $1 ))
	do
		sleep 20
		ping -c 50 $2 2>&1 >> /dev/null
		if [[ $? -eq 0 ]]
		then
			break
		fi
		iter=$(( $iter + 1 ))
	done

	iter=0
	while (( $iter < $1 ));do
		sleep 20
		if [[ $3 == "cmc0" ]];then
			getip=`/compass/mnet show ipaddr | awk 'NR==2{print $7}'`
		elif [[ $3 == "cmc1" ]];then
			getip=`/compass/mnet show ipaddr | awk 'NR==4{print $7}'`
		else
			echo $( date )": parameter is error "$3 >> $FW_LOG
			break
		fi
		if [[ $getip == $2 && $getip != "0.0.0.0" ]];then
			break
		else
			echo $( date )": getip "$getip" target ip "$2" is different,so wait" >> $FW_LOG
			iter=$(( $iter+1 ))
		fi
	done
	echo $( date )": get target cmc ip: "$getip >> $FW_LOG
	if [[ $iter == $1 ]];then
		return 1
	else
		return 0
	fi
}

#args: $1 is cmc0 or cmc1
function set_upgrade_flag
{
	typeset value=0
	typeset check_value=""
	typeset rc_value=""

	if (( ${debug_option["error"]} == 124 ));then
		printf "$(date): inject set eeprom error" >> $FW_LOG
		return 1
	fi

	if [[ $1 == "cmc0" ]];then
		value=0
		check_value+="0"
	elif [[ $1 == "cmc1" ]];then
		value=1
		check_value+="1"
	else
		echo $( date )": parameters error "$1 >> $FW_LOG
	fi
	check_value+="1"
	/compass/imm_service -write -elmt cmc -action upgd_wri -value $value
	if [[ $? != 0 ]];then
		echo $( date )": set flags to eeprom failed " >> $FW_LOG
		return 1
	fi
	rc_value=$(/compass/imm_service -check_cmc_flag)
	if [[ $rc_value != $check_value ]];then
		echo $( date )": set flags but check failed " >> $FW_LOG
		return 1
	fi

	return 0
}

#args: $1 is cmc0 or cmc1
function clear_upgrade_flag
{
	typeset value=0
	typeset check_value=""
	typeset rc_value=""

	if (( ${debug_option["error"]} == 126 ));then
		printf "$(date): inject do not clear eeprom flage" >> $FW_LOG
		return 1
	fi

	if [[ $1 == "cmc0" ]];then
		value=0
		check_value+="0"
	elif [[ $1 == "cmc1" ]];then
		value=1
		check_value+="1"
	else
		echo $( date )": parameters error "$1 >> $FW_LOG
	fi
	check_value+="0"

	/compass/imm_service -write -elmt cmc -action upgd_clr -value $value
	if [[ $? != 0 ]];then
		echo $( date )": clear flags to eeprom failed " >> $FW_LOG
		notupgrade=1
		return 1
	fi
	#imm_service -check_cmc_flag
	if [[ $? != 0 ]];then
		echo $( date )": clear flags but check failed " >> $FW_LOG
		return 1
	fi

	if (( ${debug_option["error"]} == 125 ));then
		printf "$(date): inject clear eeprom error" >> $FW_LOG
		return 1
	fi

	return 0
}

function get_cmc_version
{
	typeset cmc0_version=""
	typeset cmc1_version=""
	typeset rc=0
	typeset res=0
	typeset cmc_info=""

	cmc_info=$($IMM_CMC 2>>/tmp/fw_err )
	rc=$?
	if (( $rc == 156 || ${debug_option["error"]} == 156 ));then
		cmc0="unknown"
		cmc1="unknown"
		res=128
		printf "$(date): get cmc version failed for two cmc fault\n" >> \
			$FW_LOG
	elif (( $rc == 155 || ${debug_option["error"]} == 155 )); then
		res=127
		printf "$(date): get one cmc failed (%s)\n" $cmc_info >> $FW_LOG
	elif (( $rc == 154 || ${debug_option["error"]} == 154 )); then
		res=126
		printf "$(date): get one cmc not present (%s)\n" $cmc_info >> $FW_LOG
	elif (( $rc != 0 || ${debug_option["error"]} == 1 )); then
		cmc0="unknown"
		cmc1="unknown"
		res=1
		printf "$(date): get cmc version failed for unkown error(%s)\n" \
			$rc >> $FW_LOG
	else
		#printf "$(date): get cmc version and maybe no error\n" >> $FW_LOG
		:
	fi

	if [[ $cmc0_version != "unkown" ]];then
		if [ $1 == "cmc" ];then
			cmc0_version=$( echo $cmc_info | cut -d" " -f1 | cut -d, -f3 )
		elif [ $1 == "cpld" ];then
			cmc0_version=$( echo $cmc_info | cut -d" " -f1 | cut -d, -f4 )
		else
			echo $( date )": get cmc0 version param is unkown "$1 >> $FW_LOG
		fi
	fi

	if [[ $cmc1_version != "unkown" ]];then
		if [ $1 == "cmc" ];then
			cmc1_version=$( echo $cmc_info | cut -d" " -f2 | cut -d, -f3 )
		elif [ $1 == "cpld" ];then
			cmc1_version=$( echo $cmc_info | cut -d" " -f2 | cut -d, -f4 )
		else
			echo $( date )": get cmc1 version param is unkown "$1 >> $FW_LOG
		fi
	fi

	if (( ${debug_option["error"]} == 184 ));then
		cmc0_version="0.00"
	elif (( ${debug_option["error"]} == 185 ));then
		cmc1_version="0.00"
	elif (( ${debug_option["error"]} == 0 ));then
		#printf "$(date): no error inject\n" >> $FW_LOG
		:
	else
		printf "$(date): error inject %s\n" ${debug_option["error"]} \
		>> $FW_LOG
	fi

	if [[ $cmc0_version == "0" ]];then
		cmc0_version="unknown"
	elif [[ $cmc1_version == "0" ]];then
		cmc1_version="unknown"
	fi

	echo $cmc0_version $cmc1_version

	return $res
}

function retry_get_version
{
	typeset retry_count=0
	typeset cmc_version=()
	typeset rc=0

	while (( $retry_count < $retry_max_time ));do
		cmc_version=($(get_cmc_version "$1"))
		if (( $? == 0 ));then
			if [[ ${cmc_version[0]} != "0.00" && \
			      ${cmc_version[1]} != "0.00" ]];then
			printf "$(date): retry success %s %s\n" \
			${cmc_version[0]} ${cmc_version[1]} >> $FW_LOG
			echo ${cmc_version[0]} ${cmc_version[1]}
			fi
		fi
		retry_count=$(($retry_count+1))
		printf "$(date): retry to get %s times:%s\n" "$1" "$retry_count" >> $FW_LOG
		if (( $retry_count == 1 ));then
			sleep 60
		else
			sleep 10
		fi
	done

	return $rc
}

function check_cmc_upgrade
{
	typeset check_value=""
	typeset i=0
	typeset rc=0

	if (( ${debug_option["error"]} == 127 ));then
		printf "$(date): inject check cmc upgrade\n" >> $FW_LOG
		return 1
	fi

	if [[ $1 == "cmc0" ]];then
		check_value+="01"
	elif [[ $1 == "cmc1" ]];then
		check_value+="11"
	else
		echo $( date )": check parameter error "$1 >> $FW_LOG
		return 1
	fi
	#retry 18 times and sleep 60 every time
	while(( $i < 18 ));do
		rc_value=$(/compass/imm_service -check_cmc_flag)
		rc=$?
		if [[ $rc == 0 && $rc_value == $check_value ]];then
			echo $( date )": wait for "$1" upgrade" >> $FW_LOG
			sleep 60
			i=$(( i+1 ))
		elif [[ $rc == 0 && $rc_value != $check_value ]];then
			break
		else
			echo $( date )": read eeprom flag error " >> $FW_LOG
			return 1
		fi
	done

	if (( $i != 18 ));then
		return 0
	else
		echo $( date )": retry 18 times for waiting upgrade"$1 >> $FW_LOG
		return 1
	fi
}

# switch master cmc
# arg1 the tagert cmc number

function switch_master_cmc {
	/compass/imm_service -write -elmt cmc -action switch -elmtname $1 -value active
	if [[ $? -ne 0 ]]
	then
		echo  $( date )": switch master cmc failed" >> $FW_LOG
		return 1
	fi
	sleep 30
	cmc_no=$(( $1 - 1 ))
	mode=`/compass/mnet show cmcmode cmc $cmc_no`
	if [[ $mode == "Active" ]]
	then
		echo $( date )": switch master cmc succeeded" >> $FW_LOG
	else
		echo $( date )": switch master cmc failed" >> $FW_LOG
		return 1
	fi

	if (( ${debug_option["error"]} == 123 ));then
		printf "$(date): inject switch error\n" >> $FW_LOG
		return 1
		exit 1
	fi	

	return 0
}

# switch master cmc
# arg1 1 or 2 :cmc0 or cmc1
# arg2 retry count
function switch_cmc_retry
{
	typeset i=0
	if [[ $1 != "1" && $1 != "2" ]];then
		echo $( date )": switch cmc parameters error "$1 >> $FW_LOG
		return 1
	fi

	typeset cmc_no=$(( $1 - 1 ))
	typeset mode=`/compass/mnet show cmcmode cmc $cmc_no`
	if [[ $mode == "Active" ]]
	then
		printf "$(date): now is expected cmc status(%s,%s)\n" $cmc_no $mode >> $FW_LOG
		return 0
	fi

	while(( $i < $2 ));do
		switch_master_cmc $1
		if [[ $? == 0 ]];then
			break;
		fi
		i=$(( i+1 ))
	done

	if (( $i == $2 ));then
		return 1
	else
		return 0
	fi
}

function get_canisterid
{
	canisterid=`/compass/imm_service -read -elmt canister_version  2>>/dev/null | cut -d, -f1`
	if [[ $? != 0 ]];then
		echo $( date )": read canisterid failed" >> $FW_LOG
		return 1
	fi
	echo $canisterid
	return 0
}

function get_upgrade_ip {

	typeset cid=""
	typeset cmc_ip=""
	typeset rc=0
	
	cid=$(get_canisterid)
	if (( $? != 0 ));then
		echo $( date )": get canisterid failed" >> $FW_LOG
		rc=1
		return $?
	fi

	if [[ $cid -eq 1 ]];then
		cmc_ip=`/compass/mnet show ipaddr | awk 'NR==2{print $7}'`
	else
		cmc_ip=`/compass/mnet show ipaddr | awk 'NR==4{print $7}'`
	fi
	echo $cmc_ip
	return $rc
}

function do_close_dog
{
	echo  $( date )": ipmitool 0x30 0x24 0x00 0x00" >> $FW_LOG
	ipmitool -H $1 -U admin -P admin raw 0x30 0x24 0x00 0x00 >> $FW_LOG 2>&1
	rc=$?
	if [[ $rc != 0 ]];then
		echo  $( date )": do close dog failed "$rc >> $FW_LOG
		return 1
	fi
	return 0
}

function check_close_dog
{
	typeset res=""
	typeset rc=0

	echo  $( date )": ipmitool 0x30 0x25" >> $FW_LOG
	res=$(ipmitool -H $1 -U admin -P admin raw 0x30 0x25 2>>$FW_LOG)
	rc=$?
	if [[ $rc != 0 ]];then
		echo  $( date )": do close dog failed "$rc >> $FW_LOG
		rc=1
	else
		res=$(echo $res | cut -d" " -f1)		
		if [[ $res == "00" ]];then
			echo  $( date )": close dog ok " >> $FW_LOG
		elif [[ $res == "01" ]];then
			echo  $( date )": watch dog still on " >> $FW_LOG
			rc=1
		else
			echo  $( date )": unkown error in check dog " >> $FW_LOG
			rc=2
		fi

	fi
	return $rc
}

function close_watch_dog
{
	typeset cmc_ip=""
	typeset rc=0

	cmc_ip=$(get_upgrade_ip)

	if (( $? != 0 ));then
		echo $( date )": get upgrade ip failed" >> $FW_LOG
		rc=1
		return $rc
	fi
	do_close_dog "$cmc_ip"
	if (( $? != 0 ));then
		echo $( date )": do close watch dog failed" >> $FW_LOG
		rc=1
		return $rc
	fi
	check_close_dog "$cmc_ip"
	if (( $? != 0 ));then
		echo $( date )": watch dog still work" >> $FW_LOG
		rc=1
		return $rc
	fi
}

function yafu_upgrade_cmc
{
	if (( ${debug_option["error"]} == 5 ));then
		printf "$(date): inject yafu cmc failed\n" >> $FW_LOG
		return 1
	fi

	close_watch_dog
	if (( $? != 0 ));then
		printf "$(date): close watch dog forcely failed\n" >> $FW_LOG
		return 1
	fi

	$CMCFWDIR/Yafuflash_CMC -nw -ip $1 -u admin -p admin -d 1 $CMCFWDIR/a01CMC.bin -fb >> $FW_LOG
	if [[ $? -eq 0 ]]
	then
		echo $( date )": cmc finished upgrade to "$DCODEVER >> $FW_LOG
		wait_reboot 100 $upgrade_ip "$2"
	else
		echo $( date )": cmc failed to upgrade to "$DCODEVER >> $FW_LOG
		return 1
	fi
	return 0
}

function yafu_upgrade_cmc_cpld
{
	if (( ${debug_option["error"]} == 6 ));then
		printf "$(date): inject yafu cmc cpld failed\n" >> $FW_LOG
		return 1
	fi

	close_watch_dog
	if (( $? != 0 ));then
		printf "$(date): close watch dog forcely failed\n" >> $FW_LOG
		return 1
	fi

	$CMCFWDIR/Yafuflash_CMC -nw -ip $upgrade_ip -u admin -p admin -d 4 $CMCFWDIR/CMC_CPLD.jed -fb >> $FW_LOG
	if [[ $? -eq 0 ]]
	then
		echo $( date )": cmc cpld finished upgrade to "$ECODEVER >> $FW_LOG
		#wait for cmc reboot
		wait_reboot 100 $upgrade_ip "$2"
	else
		echo $( date )": cmc cpld failed to upgrade to "$ECODEVER >> $FW_LOG
		return 1
	fi
	return 0
}

function do_upgrade_cmc0
{
	typeset iter=0
	if [[ $1 != "cmc" && $1 != "cpld" ]];then
		echo $( date )": upgrade cmc0 parameter error "$1 >> $FW_LOG
		return 1
	fi
	#if want to upgrade cmc0, need check cmc1 whether upgrade or not
	check_cmc_upgrade cmc1
	if [[ $? != 0 ]];then
		notupgrade=1
		return 1
	fi
	#if want to upgrade cmc0, need check cmc1 whether upgrade or not
	#Maybe cmc0 is upgrade because of starting upgrade and reboot the node
	check_cmc_upgrade cmc0
	if [[ $? != 0 ]];then
		notupgrade=1
		return 1
	fi
	#write cmc upgrade flag to eeprom
	set_upgrade_flag cmc0
	if [[ $? != 0 ]];then
		notupgrade=1
		clear_upgrade_flag cmc0
		if [[ $? != 0 ]];then
			echo $( date )": clear eeprom cmc0 flag failed " >> $FW_LOG
		fi
		return 1
	fi
	standard_ip=`/compass/mnet show ipaddr | awk 'NR==2{print $7}'`
	if [[ $standard_ip == "0.0.0.0" ]];then
		echo $( date )": after switch can't get upgrade ip "$standard_ip >> $FW_LOG
		not_upgrade=1
		clear_upgrade_flag cmc0
		if [[ $? != 0 ]];then
			echo $( date )": clear eeprom cmc0 flag failed " >> $FW_LOG
		fi
		return 1
	fi
	#retry count is 3 switch to cmc1 whose value is 2
	switch_cmc_retry 2 3
	if [[ $? != 0 ]];then
		notupgrade=1
		clear_upgrade_flag cmc0
		if [[ $? != 0 ]];then
		echo $( date )": clear eeprom cmc0 flag failed " >> $FW_LOG
		fi
		return 1
	fi
	upgrade_ip=`/compass/mnet show ipaddr | awk 'NR==2{print $7}'`
	while (( $iter < 3 ));do
		if [[ $upgrade_ip == $standard_ip ]];then
			break
			echo $( date )": upgrade_ip:standard_ip "$upgrade_ip" "$standard_ip >> $FW_LOG
		else
			echo $( date )": retry to get upgrade ip" >> $FW_LOG
			wait_reboot 100 $standard_ip "cmc0"
			if (( $? == 0 )); then
				upgrade_ip=`/compass/mnet show ipaddr | awk 'NR==2{print $7}'`
			else
				iter=$(( iter+1 ))
			fi
		fi
	done
	if [[ $iter == 3 ]];then
		echo $( date )": 300 times failed upgrade_ip:standard_ip "$upgrade_ip" "$standard_ip >> $FW_LOG
		notupgrade=1
		clear_upgrade_flag cmc0
		if [[ $? != 0 ]];then
			echo $( date )": clear eeprom cmc0 flag failed " >> $FW_LOG
		fi
		return 1
	fi
	cd $CMCFWDIR
	#Maybe standy cmc(cmc0) is reboot, need to wait
	wait_reboot 100 "$standard_ip" cmc0
	if [[ $? != 0 ]];then
		not_upgrade=1
		clear_upgrade_flag cmc0
		if [[ $? != 0 ]];then
			echo $( date )": clear eeprom cmc0 flag failed " >> $FW_LOG
		fi
		return 1
	fi
	#use wiston tool to update
	if [[ $1 == "cmc" ]];then
		yafu_upgrade_cmc $upgrade_ip "cmc0"
		if [[ $? != 0 ]];then
			notupgrade=1
			cmconly=1
		fi
	else
		yafu_upgrade_cmc_cpld $upgrade_ip "cmc0"
		if [[ $? != 0 ]];then
			notupgrade=1
			cmconly=1
		fi
	fi
	#clear cmc upgrade flag to eeprom
	clear_upgrade_flag cmc0
	if [[ $? != 0 ]];then
		notupgrade=1
		cmconly=1
		return 1
	fi
}

function do_upgrade_cmc1
{
	typeset iter=0
	if [[ $1 != "cmc" && $1 != "cpld" ]];then
		echo $( date )": upgrade cmc0 parameter error "$1 >> $FW_LOG
		return 1
	fi
	#if want to upgrade cmc1, need check cmc0 whether upgrade or not
	check_cmc_upgrade cmc0
	if [[ $? != 0 ]];then
		notupgrade=1
		return 1
	fi
	#if want to upgrade cmc1, need check cmc1 whether upgrade or not
	#Maybe cmc1 is upgrade because of starting upgrade and reboot the node
	check_cmc_upgrade cmc1
	if [[ $? != 0 ]];then
		notupgrade=1
		return 1
	fi
	#write cmc upgrade flag to eeprom
	set_upgrade_flag cmc1
	if [[ $? != 0 ]];then
		notupgrade=1
		clear_upgrade_flag cmc1
		if [[ $? != 0 ]];then
			echo $( date )": clear eeprom cmc1 flag failed " >> $FW_LOG
		fi		
		return 1
	fi
	standard_ip=`/compass/mnet show ipaddr | awk 'NR==4{print $7}'`
	if [[ $standard_ip == "0.0.0.0" ]];then
		echo $( date )": after switch can't get upgrade ip "$standard_ip >> $FW_LOG
		not_upgrade=1
		clear_upgrade_flag cmc1
		if [[ $? != 0 ]];then
			echo $( date )": clear eeprom cmc1 flag failed " >> $FW_LOG
		fi
		return 1
	fi
	#retry count is 3 switch to cmc0 whose value is 1
	switch_cmc_retry 1 3
	if [[ $? != 0 ]];then
		notupgrade=1
		clear_upgrade_flag cmc1
		if [[ $? != 0 ]];then
		echo $( date )": clear eeprom cmc1 flag failed " >> $FW_LOG
		fi
		return 1
	fi
	upgrade_ip=`/compass/mnet show ipaddr | awk 'NR==4{print $7}'`
	while (( $iter < 3 ));do
		if [[ $upgrade_ip == $standard_ip ]];then
			break
			echo $( date )": upgrade_ip:standard_ip "$upgrade_ip" "$standard_ip >> $FW_LOG
		else
			echo $( date )": retry to get upgrade ip" >> $FW_LOG
			wait_reboot 100 $standard_ip "cmc1"
			if (( $? == 0 )); then
				upgrade_ip=`/compass/mnet show ipaddr | awk 'NR==4{print $7}'`
			else
				iter=$(( iter+1 ))
			fi
		fi
	done
	if [[ $iter == 3 ]];then
		echo $( date )": 300 times failed upgrade_ip:standard_ip "$upgrade_ip" "$standard_ip >> $FW_LOG
		notupgrade=1
		clear_upgrade_flag cmc1
		if [[ $? != 0 ]];then
			echo $( date )": clear eeprom cmc1 flag failed " >> $FW_LOG
		fi
		return 1
	fi
	cd $CMCFWDIR
	#Maybe standy cmc(cmc1) is reboot, need to wait
	wait_reboot 100 "$standard_ip" cmc1
	if [[ $? != 0 ]];then
		not_upgrade=1
		clear_upgrade_flag cmc1
		if [[ $? != 0 ]];then
			echo $( date )": clear eeprom cmc1 flag failed " >> $FW_LOG
		fi
		return 1
	fi
	#use wiston tool to update
	if [[ $1 == "cmc" ]];then
		yafu_upgrade_cmc $upgrade_ip "cmc1"
		if [[ $? != 0 ]];then
			notupgrade=1
			cmconly=1
		fi
	else
		yafu_upgrade_cmc_cpld $upgrade_ip "cmc1"
		if [[ $? != 0 ]];then
			notupgrade=1
			cmconly=1
		fi
	fi
	#clear cmc upgrade flag to eeprom
	clear_upgrade_flag cmc1
	if [[ $? != 0 ]];then
		notupgrade=1
		cmconly=1
		return 1
	fi
}

function do_upgrade_cmc
{
	canisterid=`/compass/imm_service -read -elmt canister_version  2>>/dev/null | cut -d, -f1`
	if [[ -z $canisterid ]];then
		echo $( date )": read canisterid failed " >> $FW_LOG
		notupgrade=1
		return 1
	fi

	if [[ $canisterid == 1 && $cmc0_ver != $DCODEVER ]] ||
	   [[ $canisterid == 1 && ${debug_option["cmc"]} == "force" ]]
	then
		echo $( date )": start to upgrade cmc0" >> $FW_LOG
		do_upgrade_cmc0 cmc
		#notupgrade is set in function do_upgrade
		#if cmc cause error, do not cause 525
		if [[ $? != 0 ]];then
			cmconly=1
			return 1
		fi
	elif [[ $canisterid == 2 && $cmc1_ver != $DCODEVER ]] ||
	     [[ $canisterid == 2 && ${debug_option["cmc"]} == "force" ]]
	then
		echo $( date )": start to upgrade cmc1" >> $FW_LOG
		do_upgrade_cmc1 cmc
		if [[ $? != 0 ]];then
			cmconly=1
			return 1
		fi
	elif [[ $canisterid == 1 && $cmc0_ver == $DCODEVER ]];then
		echo $( date )": canister 1 upgrade cmc0 finished." >> $FW_LOG
		echo $( date )": used canister 2 to upgrade cmc1." >> $FW_LOG
	elif [[ $canisterid == 2 && $cmc1_ver == $DCODEVER ]];then
		echo $( date )": canister 2 upgrade cmc1 finished." >> $FW_LOG
		echo $( date )": used canister 1 to upgrade cmc0." >> $FW_LOG
	else
		printf "Maybe a bug:canisterid(%s) or version(cmc0:%s cmc1:%s)\n" "$canisterid" \
			"$cmc0_ver" "$cmc1_ver" >> $FW_LOG
		notupgrade=1
		cmconly=1
		return 1
	fi
}

function add_to_unupgrade
{
    unupgrade_string[$pos]=$1
    unupgrade_version[$pos]=$2
    expect_version[$pos]=$3
    pos=$(( pos+1 ))
}

function show_notupgrade_list
{
	typeset i=0

	printf "%20s:%20s:%20s\n" "component name" "current version" "expect version" >> $FW_LOG
	while(( $i < $pos ));do
		printf "%20s %20s %20s\n" "${unupgrade_string[$i]}" \
			"${unupgrade_version[$i]}" "${expect_version[$i]}" >> $FW_LOG
		i=$(( i+1 ))
	done
}

function upgrade_cmc
{
	typeset cmc_ver=()
	typeset rc=""

	cmc_ver=($(get_cmc_version "cmc"))
	rc=$?
	
	if [[ $notupgrade == "1" ]];then
		add_to_unupgrade "cmc0" "${cmc_ver[0]}" $DCODEVER
		add_to_unupgrade "cmc1" "${cmc_ver[1]}" $DCODEVER
		echo $( date )": cmc not upgrade because of some error">> $FW_LOG
		return 1
	fi
	
	if [[ $rc == "128" || $rc == "1" ]];then
		echo $( date )": get cmc ver and two cmc fault, do not retry" >> $FW_LOG
		notupgrade=1
		cmconly=1
		return 1
	elif [[ $rc == "127" || ${cmc_ver[0]} == "0.00" ||\
		${cmc_ver[1]} == "0.00" ||\
		${debug_option["retry_cmc"]} == "force" ]];then
		echo $( date )": get cmc ver and one cmc fault, wait for next loop after 30 minutes so don.t retry" >> $FW_LOG
		notupgrade=1
		cmconly=1
		return 1
	elif [[ $rc == "126" ]];then
		typeset s=""
		s+="$( date ): get one cmc not preset(%s,%s), "
		s+="not support to upgrade\n"
		printf "$s\n" ${cmc_ver[0]} ${cmc_ver[1]} >> $FW_LOG
		notupgrade=1
		cmconly=1
		return 1
	else
		echo $( date )": get two cmc version" >> $FW_LOG
	fi
	
	if [[ ${cmc_ver[0]} == ${cmc_ver[1]} && ${cmc_ver[0]} == $DCODEVER && \
		${debug_option["cmc"]} != "force" ]];then
		echo $( date )": cmc is already up to date" >> $FW_LOG
		echo $( date )": cmc version: "${cmc_ver[0]} >> $FW_LOG
		return 0
	else
		[[ $debug_return == "true" ]] && echo "cmc upgrade" && return 0
		#need to assignment cmc0_ver and cmc1_ver because of gobal var
		cmc0_ver=${cmc_ver[0]}
		cmc1_ver=${cmc_ver[1]}
		echo $( date )": cmc0 version: "$cmc0_ver" cmc1 version: "$cmc1_ver >> $FW_LOG
		do_upgrade_cmc
		return $?
	fi
}

function do_upgrade_cmc_cpld
{
	canisterid=`/compass/imm_service -read -elmt canister_version  2>>/dev/null | cut -d, -f1`
	if [[ -z $canisterid ]];then
		echo $( date )": read canisterid failed " >> $FW_LOG
		notupgrade=1
		return 1
	fi

	if [[ $canisterid == 1 && $cmc0_cpld_ver != $ECODEVER ]] ||
	   [[ $canisterid == 1 && ${debug_option["cmc_cpld"]} == "force" ]]
	then
		echo $( date )": start to upgrade cmc0 cpld" >> $FW_LOG
		do_upgrade_cmc0 cpld
		if [[ $? != 0 ]];then
			cmconly=1
			return 1
		fi
	elif [[ $canisterid == 2 && $cmc1_cpld_ver != $ECODEVER ]] ||
	     [[ $canisterid == 2 && ${debug_option["cmc_cpld"]} == "force" ]]
	then
		echo $( date )": start to upgrade cmc1 cpld" >> $FW_LOG
		do_upgrade_cmc1 cpld
		if [[ $? != 0 ]];then
			cmconly=1
			return 1
		fi
	elif [[ $canisterid == 1 && $cmc0_cpld_ver == $ECODEVER ]];then
		echo $( date )": canister 1 upgrade cmc0 cpld finished." >> $FW_LOG
		echo $( date )": used canister 2 to upgrade cmc1 cpld." >> $FW_LOG
	elif [[ $canisterid == 2 && $cmc1_cpld_ver == $ECODEVER ]];then
		echo $( date )": canister 2 upgrade cmc1 cpld finished." >> $FW_LOG
		echo $( date )": used canister 1 to upgrade cmc0 cpld." >> $FW_LOG
	else
		printf "Maybe a bug:canisterid(%s) or version(cmc0:%s cmc1:%s)\n" "$canisterid" \
			"$cmc0_cpld_ver" "$cmc1_cpld_ver" >> $FW_LOG
		notupgrade=1
		cmconly=1
		return 1
	fi
}

function upgrade_cmc_cpld
{
	typeset cmc_cpld=()
	typeset rc=""

	cmc_cpld=($(get_cmc_version "cpld"))
	rc=$?

	if [[ $notupgrade == "1" ]];then
		add_to_unupgrade "cmc0_cpld" "${cmc_cpld[0]}" $DCODEVER
		add_to_unupgrade "cmc1_cpld" "${cmc_cpld[0]}" $DCODEVER
		echo $( date )": cmc not upgrade because of some error">> $FW_LOG
		return 1
	fi

	if [[ $rc == "128" || $rc == "1" ]];then
		echo $( date )": get cpld ver and two cmc fault, do not retry" >> $FW_LOG
		notupgrade=1
		cmconly=1
		return 1
	elif [[ $rc == "127" || ${cmc_cpld[0]} == "0.00" ||\
		${cmc_cpld[1]} == "0.00" ||\
		${debug_option["retry_ccpld"]} == "force" ]];then
		echo $( date )": get cmc ver and one cmc fault when upgrading cmc_cpld, wait for next loop after 30 minutes so don't retry" >> $FW_LOG
		notupgrade=1
		cmconly=1
		return 1
	elif [[ $rc == "126" ]];then
		printf "$( date ): get one cmc not preset(%s,%s), not support to
		upgrade\n" ${cmc_cpld[0]} ${cmc_cpld[1]} >> $FW_LOG
		notupgrade=1
		cmconly=1
		return 1
	else
		echo $( date )": get two cpld version" >> $FW_LOG
	fi
	if [[ ${cmc_cpld[0]} == ${cmc_cpld[1]} && ${cmc_cpld[0]} == $ECODEVER && \
		${debug_option["cmc_cpld"]} != "force" ]];then
		echo $( date )": cmc cpld is already up to date" >> $FW_LOG
		echo $( date )": cmc cpld version: "${cmc_cpld[0]} >> $FW_LOG
		return 0
	else
		echo $( date )": cmc cpld need to upgrade and do it" >> $FW_LOG
		[[ $debug_return == "true" ]] && echo "cmc cpld upgrade" && return 0
		#need to assignment cmc0_ver and cmc1_ver because of gobal var
		cmc0_cpld_ver=${cmc_cpld[0]}
		cmc1_cpld_ver=${cmc_cpld[1]}
		echo $( date )": cmc0 cpld version: "$cmc0_cpld_ver " cmc1 cpld version: "$cmc1_cpld_ver >> $FW_LOG
		do_upgrade_cmc_cpld
		return $?
	fi
}

FW_LOG=/dumps/check_upgrade_cmc.log

#Keep trace file from being too big
if [ ! -f ${FW_LOG} ]
then
    touch ${FW_LOG}
else
    typeset -i SZ
    SZ=$(${LSCMD} -s ${FW_LOG} | ${AWKCMD} -F " " '{print $1}')
    SZ=${SZ}*1024
    if [ $SZ -gt 163840 ]
    then
        tail --bytes=163840 ${FW_LOG} >/tmp/$$ 2>/dev/null
        mv -f /tmp/$$ ${FW_LOG} 2>/dev/null
    fi
fi


is_running=$(ps aux | grep -i "\(firmware.sh\)\|\(upgrade.sh\)" | grep -v "grep" | wc -l)
if [[ $is_running -eq 0 ]];then

    #setup the cmc network
    #/compass/manage-network.sh >> $FW_LOG 2>&1

    #output prompt to ttyS0
    echo "/compass/upgrade_cmc.sh Start to upgrade firmware, please wait." >> /dev/ttyS0
	echo "[$(date)]Start to upgrade cmc firmware, please wait." >> $FW_LOG

    upgrade_cmc
	rc=$?
	if [[ $rc != 0 ]];then
	    echo "[$(date)]exec upgrade_cmc fail rc=$rc,so don't upgrade cmc cpld" >>$FW_LOG
	else
        upgrade_cmc_cpld
        rc=$?
	fi
	
    echo "[$(date)]exec firmware.sh rc=$rc" >>$FW_LOG
	if [[ $notupgrade == "1" ]];then
	    echo -e '\n\n\n############ NOT UPGRADE INFO ############\n' >> $FW_LOG
	    show_notupgrade_list
    fi
else
    echo "[$(date)]another upgrade task is running, do nothing" >>${FW_LOG}
fi





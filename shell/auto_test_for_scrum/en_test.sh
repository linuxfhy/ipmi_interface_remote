#! /bin/bash
EN_TEST_DIR=$PWD

IPMITOOL=/usr/bin/ipmitool
IPMITOOL_REAL=/usr/bin/ipmitool.real
IPMITOOL_SHELL=$PWD/ipmitool.sh2


trcfile="/dumps/scrumtest.trc"

function log()
{
    echo "[$(date -d today +"%Y-%m-%d %H:%M:%S")]" $* >>${trcfile}
}

if [[ $1 =~ "short" ]]
then
    IPMITOOL_SHELL=$PWD/ipmitool_short.sh2
    log "link ipmitool--->ipmitool_short.sh2"
elif [[ $1 =~ "timeout" ]]
then
    IPMITOOL_SHELL=$PWD/ipmitool_timeout.sh2
    log "link ipmitool--->ipmitool_timeout.sh2"
fi

IPMI_INJECT=$EN_TEST_DIR/ipmi.inject
[ -e "$IPMI_INJECT" ] && source "$IPMI_INJECT"
TEST_LOG=$EN_TEST_DIR/test.log
>$TEST_LOG

set_test_evironment()
{
    [ ! -f "$IPMITOOL_REAL" ] && cp $IPMITOOL $IPMITOOL_REAL
    [ -f "$IPMITOOL_REAL" ] && ln -sb $IPMITOOL_SHELL $IPMITOOL
    chmod augo+x $IPMITOOL_SHELL
    chmod augo+x $IPMITOOL_REAL
    chmod augo+x $IPMITOOL
}
recover_evironment()
{
    [ -f "$IPMITOOL_REAL" ] && rm -fr $IPMITOOL
    [ -f "$IPMITOOL_REAL" ] && cp -a $IPMITOOL_REAL $IPMITOOL

}
echo_exit()
{
	echo "[ERROR] $@" >>/$TEST_LOG
	recover_evironment
	exit 1
}
trap "echo_exit killed by signal" INT

# $1 output, $2 cmd, $3 error string
wait_120s()
{
	out="$1"
	cmd="$2"
        ret=""
	for ((i=0; i < 50; ++i)); do
                ret="$($cmd)"
		[ "$(echo $ret | grep "$out")" ] && {
			echo -e "[SUCC] $3 (cmd $cmd expect $out)\n"
			return 0
		}
		sleep 8
	done

	echo_exit "$3 (cmd $cmd expect $out,but $ret)"
}

wait2_120s()
{
	cmd="$2"
	grepstr=`echo $1|awk -F "+" '{print $1}'`
	key=`echo $1|awk -F "+" '{print $2}'`
	value=`echo $1|awk -F "+" '{print $3}'`
	colnum=`echo "$($cmd)"|head -1|awk -v str=$key '{v="";for (i=1;i<=NF;i++) if($i==str)v=v?"":i;if (v) print v}'`
	[ -z "$colnum" ] && {
		echo -e "can not find $key in $cmd output\n"
		return 0
	}
	
	ret=""
	for ((i=0; i < 50; ++i)); do
        ret=`$cmd | grep -m 1 "$grepstr" | sed s"/$grepstr/sensor_name/" | awk -v col=$colnum '{print $col}'`
		[ "$ret" = "$value" ] && {
			echo -e "[SUCC] $3 (cmd $cmd expect $out)\n"
			return 0
		}
		sleep 8
	done

	echo_exit "$3 (cmd $cmd expect $out,but $ret)"
}

#$1 condition $2 output, $3 cmd, $4, error string
test_case()
{
   condition="$1"
   out="$2"
   cmd="$3"
   error_log="$4"
   eval $condition
   echo "$condition">$IPMI_INJECT
   echo "TEST_CASE=open">>$IPMI_INJECT
   [ -e "$IPMI_INJECT" ] && . "$IPMI_INJECT"
   echo 1111111111111 $out $cmd $error_log
   specialcmd="svcinfo lsenclosuretemperature   svcinfo lsenclosurevoltage   svcinfo lsenclosurecurrent"
   if [[ $specialcmd =~ $cmd ]]
   then
       wait2_120s "$out"   "$cmd" "$error_log"
   else
      wait_120s "$out"   "$cmd" "$error_log"
   fi
}

if [[ $1 =~ "short" ]] || [[ $1 =~ "timeout" ]]
then
   set_test_evironment
   log "inject $1"
elif [[ $1 =~ "off" ]]
then
   recover_evironment
   log "inject off"
fi

#########test voltage#########


#########test temperature#########
########test complate##########################


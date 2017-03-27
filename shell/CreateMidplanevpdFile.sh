function getmasterCMCip()
{
    ip=$(ipmitool raw 0x30 0x14)
	array=($ip)
	i=0
	ipaddr[2]=0
	
	while [ $(($i)) -lt 2 ]
	do
		ipaddr[$i]="$((16#${array[4+$((8*$i))]})).$((16#${array[5+$((8*$i))]})).$((16#${array[6+$((8*$i))]})).$((16#${array[7+$((8*$i))]}))"
		#echo "cmc${i}_eth1_ip:"${ipaddr[$i]}
		readcmd="timeout -k1 1 ipmitool -H ${ipaddr[$i]} -U admin -P admin raw 0x30 0x23"
		readresult=$(${readcmd})
		
		cmd_rc=$(($?))
		if [ ${cmd_rc} != 0 ]; then
			echo "check cmc${i} is master fail,cmd_rc:${cmd_rc}(124:timeout,127:cmd not exist)"
		fi
		
		#echo "cmc${i} is:"${readresult}"(1:master,0:slave)"
		
		if [ $((${readresult})) = 1 ]; then
			masterCMCip=${ipaddr[$i]}
			return 0
		fi
	done
	
	echo "can't get master cmc ip"
    return 1
}

##script start exec from here
masterCMCip=192.168.200.142
getmasterCMCip
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "get master cmc ip fail,cmd_rc is ${cmd_rc}"
	exit
fi

rm -rf /data/midplanevpdcache
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "rm -rf /data/midplanevpdcache fail,cmd_rc is ${cmd_rc}"
	exit
fi

mkdir /data/midplanevpdcache
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "mkdir /data/midplanevpdcache fail,cmd_rc is ${cmd_rc}"
	exit
fi


echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x04 0x2f 0x60 >/data/midplanevpdcache/ReadMidplaneVPDcache_01"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x04 0x2f 0x60 >/data/midplanevpdcache/ReadMidplaneVPDcache_01
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x03 0x2f 0x64 >/data/midplanevpdcache/ReadMidplaneVPDcache_75"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x03 0x2f 0x64 >/data/midplanevpdcache/ReadMidplaneVPDcache_75
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x07 0x2f 0x67 >/data/midplanevpdcache/ReadMidplaneVPDcache_02"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x07 0x2f 0x67 >/data/midplanevpdcache/ReadMidplaneVPDcache_02
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x07 0x2f 0x40 >/data/midplanevpdcache/ReadMidplaneVPDcache_71"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x07 0x2f 0x40 >/data/midplanevpdcache/ReadMidplaneVPDcache_71
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x06 0x2f 0x47 >/data/midplanevpdcache/ReadMidplaneVPDcache_72"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x06 0x2f 0x47 >/data/midplanevpdcache/ReadMidplaneVPDcache_72
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x06 0x2f 0x4d >/data/midplanevpdcache/ReadMidplaneVPDcache_73"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x06 0x2f 0x4d >/data/midplanevpdcache/ReadMidplaneVPDcache_73
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x07 0x2f 0x56 >/data/midplanevpdcache/ReadMidplaneVPDcache_03"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x07 0x2f 0x56 >/data/midplanevpdcache/ReadMidplaneVPDcache_03
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x08 0x2f 0xc0 >/data/midplanevpdcache/ReadMidplaneVPDcache_17"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x08 0x2f 0xc0 >/data/midplanevpdcache/ReadMidplaneVPDcache_17
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x08 0x2f 0xc8 >/data/midplanevpdcache/ReadMidplaneVPDcache_18"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x08 0x2f 0xc8 >/data/midplanevpdcache/ReadMidplaneVPDcache_18
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x08 0x30 0x60 >/data/midplanevpdcache/ReadMidplaneVPDcache_59"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x08 0x30 0x60 >/data/midplanevpdcache/ReadMidplaneVPDcache_59
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x08 0x30 0x68 >/data/midplanevpdcache/ReadMidplaneVPDcache_60"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x08 0x30 0x68 >/data/midplanevpdcache/ReadMidplaneVPDcache_60
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x08 0x2f 0xac >/data/midplanevpdcache/ReadMidplaneVPDcache_20"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x08 0x2f 0xac >/data/midplanevpdcache/ReadMidplaneVPDcache_20
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x08 0x2f 0xa4 >/data/midplanevpdcache/ReadMidplaneVPDcache_19"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x08 0x2f 0xa4 >/data/midplanevpdcache/ReadMidplaneVPDcache_19
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x04 0x2f 0xe8 >/data/midplanevpdcache/ReadMidplaneVPDcache_05"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x04 0x2f 0xe8 >/data/midplanevpdcache/ReadMidplaneVPDcache_05
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x04 0x30 0x00 >/data/midplanevpdcache/ReadMidplaneVPDcache_07"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x04 0x30 0x00 >/data/midplanevpdcache/ReadMidplaneVPDcache_07
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x04 0x30 0x04 >/data/midplanevpdcache/ReadMidplaneVPDcache_09"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x04 0x30 0x04 >/data/midplanevpdcache/ReadMidplaneVPDcache_09
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x10 0x2f 0xec >/data/midplanevpdcache/ReadMidplaneVPDcache_11"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x10 0x2f 0xec >/data/midplanevpdcache/ReadMidplaneVPDcache_11
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x01 0x2f 0xfc >/data/midplanevpdcache/ReadMidplaneVPDcache_13"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x01 0x2f 0xfc >/data/midplanevpdcache/ReadMidplaneVPDcache_13
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x10 0x30 0x08 >/data/midplanevpdcache/ReadMidplaneVPDcache_15"
timeout -k1 1 ipmitool -H ${masterCMCip} -U admin -P admin raw 0x06 0x52 0x0B 0xA0 0x10 0x30 0x08 >/data/midplanevpdcache/ReadMidplaneVPDcache_15
cmd_rc=$(($?))
if [ ${cmd_rc} != 0 ]; then
    echo "cmd exec fail,cmd_rc is ${cmd_rc}"
	exit
fi

echo "Store midplane vpd to cache file successfully"


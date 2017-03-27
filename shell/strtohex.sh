#!bin/bash
rtxt=0x$(echo $(echo "  80"))
echo "rtxt=$rtxt"
rval=$(($rtxt))
#rtxt=0x$(echo $(cat data) | awk)
echo $rval

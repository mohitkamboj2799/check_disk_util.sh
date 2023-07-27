#!/bin/bash
# ---------------------------------------------------- #
# File : check_disk_util.sh
# Author : Esteban Monge
# Email : emonge@gbm.net
# Date : 10/06/2014
# Version: 0.1 Gamma "Hulk state"
# ---------------------------------------------------- #

device=""
warning=80
critical=90
was_warning=""
was_critical=""

function help {
        echo "Usage"
        echo "check_disk {-w limit -c limit -d device}"
        echo "Options:"
        echo "-h"
        echo "   Print detailed help screen"
        echo "-w=INTEGER"
        echo "   Exit with WARNING status if more than INTEGER percentaje of utilization are used"
        echo "-c=INTEGER"
        echo "   Exit with CRITICAL status if more than INTEGER percentaje of utilization are used"
        echo "-d=<STRING>"
        echo "   Device without complete route"
        echo " "
        echo "Example:"
        echo "check_disk_util -w 80 -c 90 -d sda1"
        echo "   Checks /dev/sda1 at 80% and 90% of disk utilization"
        echo "check_disk_util -w 80 -c 90 -d sda"
        echo "   Checks /dev/sda1, /dev/sda2, /dev/sda3, etc (regular expression) at 80% and 90% of disk utilization"
        exit 0
}


while getopts "w:c:d:h" args; do
        case $args in
                w) warning=$OPTARG
                        ;;
                c) critical=$OPTARG
                        ;;
                d) device=$OPTARG
                        ;;
                h) help
                        ;;
        esac
done

if [[ $critical -lt $warning ]];then
        echo "UNKNOWN: Warning threshold must be lower than Critical threshold"
        exit 4
fi

column_number=`iostat -x | grep -e "Device" | awk '{print NF}'`

while read line
do
        device=`echo $line | awk '{print $1}'`
        disk_util=`echo $line | awk '{print $2}'`

        if [ ${disk_util%.*} -ge $critical ];then
                echo "CRITICAL: $device disk utilization $disk_util%"
                was_critical=1
        else if [ ${disk_util%.*} -ge $warning ];then
                echo "WARNING: $device disk utilization $disk_util%"
                was_warning=1
                else echo "OK: $device disk utilization $disk_util%"
             fi
        fi

done < <(iostat -x |grep -e "$device" | awk -v column=$column_number '/sd|dm/ {print $1,$column}')

if [[ $was_critical -eq 1 ]];then
        exit 2
fi
if [[ $was_warning -eq 1 ]];then
        exit 1
fi
exit 0
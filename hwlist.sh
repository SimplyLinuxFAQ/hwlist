#!/bin/bash
##---------- Author : Sadashiva Murthy M ----------------------------------------------------##
##---------- Published on : http://simplylinuxfaq.blogspot.in -------------------------------##
##---------- Purpose : To quickly & interactively find out hardware  details in a server------##
##---------- Tested on : RHEL7/6/5/, SLES12/11, Ubuntu14, Mint16, Boss6(Debian) variants.----##
##---------- Updated version : 6 (modified 15th-June-2017) interactive & user-friendly.------##
##-----NOTE: This script requires root privileges, otherwise you could run the script -------##
##---- as a sudo user who has got root privileges. ------------------------------------------##
##----------- "sudo /bin/bash <ScriptName> <arguments>" -------------------------------------##

S="************************************"
D="-------------------------------------"

#------Checking the availability of dmidecode package------#
if [ ! -x /usr/sbin/dmidecode ];
then
    echo -e "Error : Either \"dmidecode\" command not available OR \"dmidecode\" package is not properly installed. Please make sure this package is installed and working properly!\n\n"
    exit 1
fi

#------Checking the availability of smartmontools package------#
if [ ! -x /usr/sbin/smartctl ];
then
   echo -e "Error : Either \"smartctl\" command not available OR \"smartmontools\" package is not properly installed. Please make sure this package is installed and working properly!\n\n"
    exit 1
fi

#------Checking the availability of sysstat package------#
if [ ! -x /usr/bin/mpstat ];
then
   echo -e "Error : Either \"mpstat\" command not available OR \"sysstat\" package is not properly installed. Please make sure this package is installed and working properly!\n\n"
    exit 1
fi

#------Creating functions for easy usage------#
#------Print welcome message at the top------#
head_fun()
{	
echo -e "\n**********************************************************************************************************" 
echo -e "<>------------<> Welcome to hwlist script which fetches hardware details from your system <>------------<>" 
echo -e "**********************************************************************************************************"
}

#------Print hostname, OS architecture and kernel version-----#
os_fun()
{
echo -e "\n\t\t Operating System Details" 
echo -e "\t $S"
printf "Hostname\t\t\t\t :" $(hostname -f > /dev/null 2>&1) && printf " $(hostname -f)" || printf " $(hostname -s)"

if [ -e /usr/bin/lsb_release ]
then
	echo -e "\nOperating System\t\t\t :" $(lsb_release -d|awk -F: '{print $2}'|sed -e 's/^[ \t]*//') 
else
	echo -e "\nOperating System\t\t\t :" $(cat /etc/system-release) 
fi

echo -e "Kernel Version\t\t\t\t :" $(uname -r) 

printf "OS Architecture\t\t\t\t :" $(arch | grep x86_64 2>&1 > /dev/null) && printf " 64 Bit OS\n"  || printf " 32 Bit OS\n"

#--------Print system uptime-------#

UPTIME=$(uptime)
echo $UPTIME|grep day 2>&1 > /dev/null
if [ $? != 0 ]
then
  echo $UPTIME|grep -w min 2>&1 > /dev/null && echo -e "System Uptime \t\t\t\t : "$(echo $UPTIME|awk '{print $2" by "$3}'|sed -e 's/,.*//g')" minutes"  || echo -e "System Uptime \t\t\t\t : "$(echo $UPTIME|awk '{print $2" by "$3" "$4}'|sed -e 's/,.*//g')" hours" 
else
  echo -e "System Uptime \t\t\t\t :" $(echo $UPTIME|awk '{print $2" by "$3" "$4" "$5" hours"}'|sed -e 's/,//g') 
fi
echo -e "Current System Date & Time \t\t : "$(date +%c)

#-------Fetch server hardware details--------#

echo -e "\n\t\t System Hardware Details" 
echo -e "\t $S"
echo -e "Product Name \t\t\t\t :" $(dmidecode -s system-product-name) 
echo -e "Manufacturer \t\t\t\t :" $(dmidecode -s system-manufacturer) 
echo -e "System Serial Number \t\t\t :" $(dmidecode -s system-serial-number) 
echo -e "System Version \t\t\t\t :" $(dmidecode -s system-version) 

#-------Fetch motherboard details--------#

echo -e "\n\t\t System Motherboard Details" 
echo -e "\t $S"
echo -e "Manufacturer \t\t\t\t :" $(dmidecode -s baseboard-manufacturer) 
echo -e "Product Name \t\t\t\t :" $(dmidecode -s baseboard-product-name) 
echo -e "Version \t\t\t\t :" $(dmidecode -s baseboard-version) 
echo -e "Serial Number \t\t\t\t :" $(dmidecode -s baseboard-serial-number) 

#-------Fetch BIOS details--------#

echo -e "\n\t\t System BIOS Details" 
echo -e "\t $S"
echo -e "BIOS Vendor \t\t\t\t :" $(dmidecode -s bios-vendor) 
echo -e "BIOS Version \t\t\t\t :" $(dmidecode -s bios-version) 
echo -e "BIOS Release Date \t\t\t :" $(dmidecode -s bios-release-date) 
}

#-------Fetch processor details--------#
proc_fun()
{
LPROC=$(dmidecode --type processor)

echo -e "\n\t\tSystem Processor Details (CPU)" 
echo -e "\t $S****"
echo -e "Manufacturer\t\t\t\t:" $(echo "$LPROC"|grep Manufacturer|uniq|awk '{print $2}') 
echo -e "Model Name\t\t\t\t:" $(echo "$LPROC"|grep Version|uniq|sed -e 's/Version://' -e 's/^[ \t]*//') 
echo -e "CPU Family\t\t\t\t:" $(grep "family" /proc/cpuinfo|uniq|awk -F: '{print $2}') 
echo -e "CPU Stepping\t\t\t\t:" $(grep "stepping" /proc/cpuinfo|awk -F: '{print $2}'|uniq) 

if [ -e /usr/bin/lscpu ]
then
{
	echo -e "No. Of Processor(s)\t\t\t:" $(lscpu|grep -w "Socket(s):"|awk -F: '{print $2}') 
	echo -e "No. of Core(s) per processor\t\t:" $(lscpu|grep -w "Core(s) per socket:"|awk -F: '{print $2}') 
}
else
{
	echo -e "No. Of Processor(s) Found\t\t:" $(grep -c processor /proc/cpuinfo) 
	echo -e "No. of Core(s) per processor\t\t:" $(grep "cpu cores" /proc/cpuinfo|uniq|wc -l) 
}
fi

echo -e "\n\tDetails Of Each Processor (Based On dmidecode)\t\t"
echo -e "\t $D" 

COUNT=$(grep -c processor /proc/cpuinfo)

SOCK=$( echo "$LPROC" |egrep -w -m$COUNT "Socket Designation:" |awk -F: '{print $1 "\t" ":"$2}')
TYPE=$( echo "$LPROC" | egrep -w -m$COUNT "Type:" | awk -F: '{print $1 "\t\t\t" ":"$2}')
FAM=$( echo "$LPROC" | egrep -w -m$COUNT "Family:" | awk -F: '{print $1"\t\t\t" ":"$2}')
VER=$( echo "$LPROC" | egrep -w -m$COUNT "Version:" | awk -F: '{print $1 "\t\t\t" ":"$2}')
VOL=$( echo "$LPROC" | egrep -w -m$COUNT "Voltage:" | awk -F: '{print $1 "\t\t\t" ":"$2}')
MXSP=$( echo "$LPROC" | egrep -w -m$COUNT "Max Speed:" | awk -F: '{print $1 "\t\t" ":"$2}')
CRSP=$( echo "$LPROC" | egrep -w -m$COUNT "Current Speed:" | awk -F: '{print $1 "\t\t" ":"$2}')
SRL=$( echo "$LPROC" | egrep -w -m$COUNT "Serial Number:" | awk -F: '{print $1 "\t\t" ":"$2}')
TAG=$( echo "$LPROC" | egrep -w -m$COUNT "Asset Tag:" | awk -F: '{print $1 "\t\t" ":"$2}')
PART=$( echo "$LPROC" | egrep -w -m$COUNT "Part Number:" | awk -F: '{print $1 "\t\t" ":"$2}')

for (( num=1; num <= $COUNT; num++ ))
do
   echo "$SOCK"|sed "$num!d" 
   echo "$TYPE"|sed "$num!d"
   echo "$FAM"|sed "$num!d"
   echo "$VER"|sed "$num!d"
   echo "$VOL"|sed "$num!d"
   echo "$MXSP"|sed "$num!d"
   echo "$CRSP"|sed "$num!d"
   echo "$SRL"|sed "$num!d"
   echo "$TAG"|sed "$num!d"
   echo "$PART"|sed "$num!d"
   echo -e
done
}

#-------Fetch system memory (RAM) details--------#
mem_fun()
{
dmidecode --type memory > /tmp/mem.out
sed -n -e '/Memory Device/,$p' /tmp/mem.out > /tmp/memory-device.out
echo -e "\n\t\tSystem Memory Details (RAM)" 
echo -e "\t $S" 

echo -e "Total RAM (/proc/meminfo)\t\t: "$(grep MemTotal /proc/meminfo|awk '{print $2/1024}') "MB OR" $(grep MemTotal /proc/meminfo|awk '{print $2/1024/1024}') "GB"
echo -e "Error Detecting Method \t\t\t: "$(grep -w "Error Detecting Method" /tmp/mem.out|awk -F: '{print $2}')
echo -e "Error Correcting Capabilities \t\t: "$(grep -w -m1 "Error Correcting Capabilities" /tmp/mem.out|awk -F: '{print $2}')
echo -e "No. Of Memory Module(s) Found\t\t: "$(grep -w "Installed Size" /tmp/mem.out|grep -vc "Not Installed")

echo -e "\n\t  Memory Module(s) Detected \t\t\t" 
echo -e "\t ----------------------------------" 
grep "Installed Size" /tmp/mem.out|grep -v "Not"|awk -F: '{print "\t" $2}'
echo -e "\n\t\t Hardware Specification Of Each Memory Module(s) " 
echo -e "\t\t $D" 

grep -E '[[:blank:]]Size: [0-9]+' /tmp/memory-device.out -A11|egrep -v "Set|Tag"|sed -e 's/^\s*//'|awk -F: '{print $1}' > /tmp/m1.out
grep -E '[[:blank:]]Size: [0-9]+' /tmp/memory-device.out -A11|egrep -v "Set|Tag"|awk -F: '{print $2}'|sed  -e 's/^\s*//' > /tmp/m2.out
pr -t -m -w 50 -S:\  /tmp/m1.out /tmp/m2.out |sed -e 's/^/\t\t/g' 
rm -rf /tmp/{mem.out,memory-device.out,m1.out,m2.out}
}

#-------Fetch PCI device details--------#
pci_fun()
{
echo -e "\n\t\t PCI Controller(s) Found \t\t\t" 
echo -e "\t $S" 
lspci | grep controller|awk -F: '{print $2}'|sed -e 's/^....//'|awk '{ printf "%-10s\n", $1}' > /tmp/n1.txt
lspci | grep controller|awk -F: '{print ":"$3}'|sed -e 's/^\s*//' -e '/^$/d' -e 's/^/\t\t\t/g' > /tmp/n2.txt
paste -d" " /tmp/n1.txt /tmp/n2.txt|sort -u 
rm -rf /tmp/{n1.txt,n2.txt}
}

#-------Fetch hard drive/disk (storage) details--------#
disk_fun()
{
echo -e "\t\t Storage Device Details \t\t\t" 
echo -e "\t $S"
echo -e "$D$D" 
echo -e "Device type \t\t Logical Name \t\t\t Size" 
echo -e "$D$D" 

TDISK=$(/sbin/fdisk -l 2> /dev/null|grep Disk|grep bytes|egrep -v "loop|mapper|md")
LDISK=$(echo "$TDISK"|awk '{print $2}'|sed 's/\://'|awk -F/ '{print $3}'|sort)

service multipathd status > /dev/null 2>&1 && {
 MDISKS=$(multipath -l|grep sd[a-z0-9]|awk '{print $(NF-4)}'|sort)
 MFOUND="y"
 MDRIVES=$(multipath -l|grep DISK|awk '{print $1}'|sort)
 } || MFOUND="n"

if [ $MFOUND == y ]
then
{
 for L in $(echo "$LDISK");do
  echo "$MDISKS"|grep "$L" 2>&1 > /dev/null || echo "$TDISK"|grep "$L"|sed -e 's/://' -e 's/,//'|awk '{print $1"\t\t\t"$2"\t\t\t"$3 $4}'; done

echo -e "\n\t ****These are multipathed drives***** "
for M in $(echo "$MDRIVES");do
 echo -e "multipathed \t\t /dev/mapper/$M \t\t $(multipath -l|grep -w "$M" -A1|grep size|awk '{print $1}'|awk -F= '{print $2}')"; done
}
else
 echo "$TDISK"|sed -e 's/://' -e 's/,//'|awk '{print $1"\t\t\t"$2"\t\t\t"$3 $4}'
fi

##---------Printing each disk details depending on version-----------#
echo -e "\n\t\t Details Of Each Hard Drive(s) (local) Found" 

if [ $MFOUND == y ]
then
{
 for L in $(echo "$LDISK");do
  {
   echo "$MDISKS"|grep "$L" 2>&1 > /dev/null || {
     echo -e "\t$D$D"
     echo -e "\t\t\t Disk :" $L
     echo -e "\t$D$D"
     echo -e "\t Disk Model \t\t\t :" $(cat /sys/block/$L/device/model 2> /dev/null)
     echo -e "\t Disk Vendor \t\t\t :" $(cat /sys/block/$L/device/vendor 2> /dev/null)
     echo -e "\t Disk Serial Number \t\t :" $(/usr/sbin/smartctl -i $L|grep "Serial Number"|awk -F: '{print $2}' 2> /dev/null)
     echo -e "\t Drive Firmware Version \t :" $(/usr/sbin/smartctl -i $L|grep "Firmware Version"|awk -F: '{print $2}' 2> /dev/null)
     echo -e "\t Device Path \t\t\t :" $(ls -l /dev/disk/by-path/|grep -w $L|grep -o "pci.*" 2> /dev/null)
    }
  } done
}
else
{
  for L in $(echo "$LDISK");do 
  {
     echo -e "\t$D$D"
     echo -e "\t\t\t Disk :" $L
     echo -e "\t$D$D"
     echo -e "\t Disk Model \t\t\t :" $(cat /sys/block/$L/device/model 2> /dev/null)
     echo -e "\t Disk Vendor \t\t\t :" $(cat /sys/block/$L/device/vendor 2> /dev/null)
     echo -e "\t Disk Serial Number \t\t :" $(/usr/sbin/smartctl -i $L|grep "Serial Number"|awk -F: '{print $2}' 2> /dev/null)
     echo -e "\t Drive Firmware Version \t :" $(/usr/sbin/smartctl -i $L|grep "Firmware Version"|awk -F: '{print $2}' 2> /dev/null)
     echo -e "\t Device Path \t\t\t :" $(ls -l /dev/disk/by-path/|grep -w $L|grep -o "pci.*" 2> /dev/null)
  } done
}
fi

}

#-------Fetch network hardware details--------#
net_fun()
{
ANET=$(ip a|grep ^[0-9]|egrep -v "lo|virbr|vlan|sit|vnet"|grep -v DOWN|awk -F: '{print $2}'|sed 's/^[ \t]*//')

echo -e "\n\t\t Network Hardware Info"  
echo -e "\t $S"  
echo -e "Ethernet Controller Name \t\t:" $(lspci|grep Ethernet|awk -F: '{print $3}'|uniq|sed 's/^[ /t]*//')
echo -e "Total Network Interface(s)\t\t:" $(ip a|grep ^[0-9]|egrep -v -c "lo|virbr|vlan|sit|vnet") 
echo -e "Active Network Interface(s)\t\t:" $(echo "$ANET"|grep -v '^$'|wc -l) 
echo -e "\n" 
echo -e "\t Details Of Active Network Interface(s) Found" 
echo -e "\t $D" 

if [ "$ANET" != "" ]
then
{
  for i in $(echo "$ANET")
  do
  {
      echo -e "\t Interface Name \t\t :" $i 
      echo -e "\t IP Address \t\t\t :" $(ip a s $i|grep -w 'inet' 2>&1 > /dev/null && ip a s $i|grep -w 'inet'|awk '{print $2}'|sed 's/[/]24//' || echo "\"Not Set\"") 
      echo -e "\t Hardware Address \t\t :" $(ip a s $i|grep 'ether'|awk '{print $2}') 
      echo -e "\t Driver Module Name \t\t :" $(ethtool -i $i|grep driver|awk '{print $2}') 
      echo -e "\t Driver Version \t\t :" $(ethtool -i $i|grep -A1 -i driver|grep version|awk '{print $2}') 
      echo -e "\t Firmware Version \t\t :" $(ethtool -i $i|grep firmware|awk '{print $2}') 
      echo -e "\t Speed \t\t\t\t :" $(ethtool $i|grep Speed|awk '{print $2}') 
      echo -e "\t Duplex Mode \t\t\t : $(ethtool $i|grep Duplex|awk '{print $2}')\n"
  }
  done
}
else
  echo -e "\t No network interfaces active!"
fi  
}

#----------Simple health check (resource stats)--------------#
health_check()
{
MOUNT=$(mount|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs"|sort -u -t' ' -k1,2)
#FS_USAGE=$(df -PTh|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs"|sort -u -t' ' -k1,6)
FS_USAGE=$(df -PTh|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs"|sort -k6n)

#IUSAGE=$(df -PThi|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs"|sort -u -t' ' -k1,6)
IUSAGE=$(df -PThi|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs"|sort -k6n)

echo -e "$S" 
echo -e "\tSystem Health Status" 
echo -e "$S" 

#--------Check for any read-only file systems--------#
echo -e "\nChecking For Read-only File System"
echo -e "$D"
echo "$MOUNT"|grep -w \(ro\) && echo -e "\n.....Read Only file system[s] found"|| echo -e ".....No read-only file systems found. "


#--------Check for currently mounted file systems--------#
echo -e "\n\nChecking For Currently Mounted File Systems"
echo -e "$D$D"
echo "$MOUNT"|column -t


#--------Check disk usage on all mounted file systems--------#
echo -e "\n\nChecking For Disk Usage On Mounted File Systems"
echo -e "$D$D"
echo -e "( 0-90% = OK/HEALTHY, 90-95% = WARNING, 95-100% = CRITICAL )"
echo -e "$D$D"
echo -e "Mounted File System Utilization (Percentage Used):\n" 

echo "$FS_USAGE"|awk '{print $7}' > /tmp/s1.out
echo "$FS_USAGE"|awk '{print $6}'|sed -e 's/%//g' > /tmp/s2.out
> /tmp/s3.out
for i in $(cat /tmp/s2.out);
do
{
  if [ $i -ge 95 ];
   then
     echo -e $i"%" "\e[47;31m ------ CRITICAL \e[0m" >> /tmp/s3.out;
   elif [[ $i -ge 90 && $i -lt 95 ]];
   then
     echo -e $i"%" "\e[43;31m ------ WARNING \e[0m" >> /tmp/s3.out; 
   else
     echo -e $i"%" "\e[47;32m ------ OK/HEALTHY \e[0m" >> /tmp/s3.out;
  fi
}
done
paste -d"\t" /tmp/s1.out /tmp/s3.out

#--------Check for any zombie processes--------#
echo -e "\n\nChecking For Zombie Processes"
echo -e "$D"
ps -eo stat|grep -w Z 1>&2 > /dev/null 
if [ $? == 0 ]
then
  echo -e "Number of zombie process on the system are :" $(ps -eo stat|grep -w Z|wc -l) 
  echo -e "\n  Details of each zombie processes found	"
  echo -e "  $D"
  ZPROC=$(ps -eo stat,pid|grep -w Z|awk '{print $2}')
  for i in $(echo "$ZPROC")
  do
      ps -o pid,ppid,user,stat,args -p $i
  done
else
 echo -e "No zombie processes found on the system."
fi

#--------Check Inode usage--------#
echo -e "\n\nChecking For INode Usage"
echo -e "$D$D"
echo -e "( 0-90% = OK/HEALTHY, 90-95% = WARNING, 95-100% = CRITICAL )"
echo -e "$D$D"
echo -e "INode Utilization (Percentage Used):\n"

echo "$IUSAGE"|awk '{print $7}' > /tmp/s1.out
echo "$IUSAGE"|awk '{print $6}'|sed -e 's/%//g' > /tmp/s2.out
> /tmp/s3.out

for i in $(cat /tmp/s2.out);
do
if [[ $i = *[[:digit:]]* ]];
then
{
if [ $i -ge 95 ];
then
   #echo $i"% ---- CRITICAL" >> /tmp/s3.out;
   echo -e $i"%" "\e[47;31m ------ CRITICAL \e[0m" >> /tmp/s3.out;
 elif [[ $i -ge 90 && $i -lt 95 ]];
then
   #echo $i"% ---- WARNING" >> /tmp/s3.out;
   echo -e $i"%" "\e[43;31m ------ WARNING \e[0m" >> /tmp/s3.out;
 else
   #echo $i"% ---- OK/HEALTHY" >> /tmp/s3.out;
   echo -e $i"%" "\e[47;32m ------ OK/HEALTHY \e[0m" >> /tmp/s3.out;
fi
}
else
 echo -e $i"%" "\e[47;32m ------ OK/HEALTHY \e[0m (Inode Percentage details not available)" >> /tmp/s3.out
fi
done

paste -d"\t" /tmp/s1.out /tmp/s3.out

#--------Check for SWAP Utilization--------#
echo -e "\n\nChecking SWAP Details"
echo -e "$D"
echo -e "Total Swap Memory in MB : "$(grep -w SwapTotal /proc/meminfo|awk '{print $2/1024}')", in GB : "$(grep -w SwapTotal /proc/meminfo|awk '{print $2/1024/1024}')
echo -e "Swap Free Memory in MB : "$(grep -w SwapFree /proc/meminfo|awk '{print $2/1024}')", in GB : "$(grep -w SwapFree /proc/meminfo|awk '{print $2/1024/1024}')

#--------Check for Processor Utilization (current data)--------#
echo -e "\n\nChecking For Processor Utilization"
echo -e "$D"
echo -e "\nCurrent Processor Utilization Summary :\n"
mpstat|tail -2

#--------Check for load average (current data)--------#
echo -e "\n\nChecking For Load Average"
echo -e "$D"
echo -e "Current Load Average : $(uptime|grep -o "load average.*"|awk '{print $3" " $4" " $5}')"


#------Print most recent 3 reboot events if available----#
echo -e "\n\nMost Recent 3 Reboot Events"
echo -e "$D$D" 
last -x 2> /dev/null|grep reboot 1> /dev/null && /usr/bin/last -x 2> /dev/null|grep reboot|head -3 || echo -e "No reboot events are recorded."

#------Print most recent 3 shutdown events if available-----#
echo -e "\n\nMost Recent 3 Shutdown Events"
echo -e "$D$D"
last -x 2> /dev/null|grep shutdown 1> /dev/null && /usr/bin/last -x 2> /dev/null|grep shutdown|head -3 || echo -e "No shutdown events are recorded."

#--------Print top 5 most memory consuming resources---------#
echo -e "\n\nTop 5 Memory Resource Hog Processes"
echo -e "$D$D"
ps -eo pmem,pcpu,pid,ppid,user,stat,args | sort -k 1 -r | head -6|sed 's/$/\n/'

#--------Print top 5 most CPU consuming resources---------#
echo -e "\n\nTop 5 CPU Resource Hog Processes"
echo -e "$D$D"
ps -eo pcpu,pmem,pid,ppid,user,stat,args | sort -k 1 -r | head -6|sed 's/$/\n/'
}

#-------Simple footer message-------#
foot_fun()
{
	echo -e "NOTE:- If any of the above fields are marked as \"blank\" or \"NONE\" or \"UNKNOWN\" or \"Not Available\" or \"Not Specified\" that
means either there is no value present in the system for these fields, otherwise that value may not be available." 
	echo -e "\n\t\t %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%" 
	echo -e "\t\t <>--------<> Powered By : http://simplylinuxfaq.blogspot.in <>--------<>" 
	echo -e "\t\t %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
}

main_prog()
{
head_fun
os_fun
mem_fun
proc_fun
disk_fun
pci_fun
net_fun
health_check
foot_fun
}

case "$1" in 
	--RAM|--ram|--memory)
	 mem_fun
	 ;;
	--cpu|--CPU)
	 proc_fun
	 ;;
	--disk)
	 disk_fun
	 ;;
	--network)
	 net_fun
	 ;;
	--details|--all)
	 main_prog
	 ;;
	--dump)
	 if [ $# != 2 ];
	 then
	  echo -e "Error: Invalid Arguments Passed." 
	  echo -e "Usage: $0 --dump <PathForDumpFile>"
	  exit 1
	fi
	 main_prog > $2
	 ;;
	--os|--system)
	 os_fun	
	;;
	--pci|--PCI)
	 pci_fun
	;;
	--health|--HEALTH)
	 health_check
	;;  
	--help|--info)
	 echo -e "To print System (OS) details: ------------------- $0 --system OR --os"
	 echo -e "To print memory details (RAM) : ----------------- $0 --memory OR --RAM OR --ram"
	 echo -e "To print CPU (processor) details: --------------- $0 --CPU OR --cpu"
	 echo -e "To print disk (hard disk/drive) details: -------- $0 --disk"
	 echo -e "To print network hardware details: -------------- $0 --network"
	 echo -e "To print PCI devices: --------------------------- $0 --pci"
	 echo -e "To get complete system hardware details : ------- $0 --all OR --details"
	 echo -e "To get system health status : ------------------- $0 --health"
	 echo -e "To dump complete system details to a file : ----- $0 --dump <PathForDumpFile>"
	;;
	*)
	echo "Usage: $0 {--memory|--cpu|--disk|--network|--details|--os|--health|--dump <PathForDumpFile> }"
	echo -e "To get help : $0 --help|--info"
        exit 2
	;;
esac

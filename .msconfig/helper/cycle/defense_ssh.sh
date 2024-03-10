#! /bin/bash

SSH_Log="/var/log/secure"
ms_home=".msconfig"
IP_tmp="data/tmp/ssh_failed.txt"
Log_tmp="data/log/ssh_deny.log"
Host_Deny="/etc/hosts.deny"
MAX_TRY=5

# create files
cd ~
cd $ms_home
touch $IP_tmp $Log_tmp

cat ${SSH_Log}|awk '/Failed/{print $(NF-3)}'|sort|uniq -c|awk '{print $2"="$1;}' > ${IP_tmp}
for i in `cat ${IP_tmp}`
do
  IP=`echo $i |awk -F= '{print $1}'`
  NUM=`echo $i|awk -F= '{print $2}'`
  if [ $NUM -gt ${MAX_TRY} ]; then
    grep $IP ${Host_Deny}
    if [ $? -gt 0 ];then
      echo "sshd:$IP:deny" >> ${Host_Deny}
      echo -e "IP:[$IP] \t Append into denyHost \t - try counts:$NUM" >> ${Log_tmp}
    fi
  fi
done


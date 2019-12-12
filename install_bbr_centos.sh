#!/bin/bash

CentOS_Version=`cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | cut -d'.' -f1`
KVersion=4.9.13-1

if [ -z ${CentOS_Version} ]
then
	CentOS_Version=0
fi

if [ ${CentOS_Version} -lt 6 ]
then
	echo "Sorry, I can only support CentOS 6/7 yet."
	exit
fi

if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
	BIT_VER=x64
else
	BIT_VER=x86
fi

if [ ${BIT_VER} != 'x64' ]
then
	echo "Sorry, I can only support x64 yet."
	exit
fi

echo "Now I will replace the system kernel to ${KVersion}..."
echo "Start installing"

MODSCRIPT=/usr/share/dracut/modules.d/90kernel-modules/installkernel
QOCC=`grep blk_init_queue $MODSCRIPT|wc -l`
if [ $QOCC -eq 1 ]
then
	sed -i 's/blk_init_queue/blk_mq_init_queue/' $MODSCRIPT
fi
if [ ${CentOS_Version} -eq 7 ]
then
	rpm -Uvh --force http://soft.wellphp.com/kernels/x86_64/kernel-ml-${KVersion}.el${CentOS_Version}.centos.x86_64.rpm
else
	rpm -Uvh --force http://soft.wellphp.com/kernels/x86_64/kernel-ml-${KVersion}.el${CentOS_Version}.x86_64.rpm
fi
if [ $QOCC -eq 1 ]
then
	sed -i 's/blk_mq_init_queue/blk_init_queue/' $MODSCRIPT
fi
echo "Checking if the installtion is ok"
KGRUB2=`ls /etc/grub2.cfg|wc -l`
if [ ${KGRUB2} -eq 1 ]
then
	INS_OK=`awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg | grep ${KVersion} | grep -i -v debug | grep -i -v rescue | cut -d' ' -f1`
	if [ -z ${INS_OK} ]
	then
		echo "Sorry, install failed, please contact the author"
		exit
	fi
	yum install -y grub2-tools
	
	grub2-set-default ${INS_OK}
else
	KGRUB=`ls /boot/grub/grub.conf|wc -l`
	if [ ${KGRUB} -eq 1 ]
	then
		INS_OK=`grep '^title ' /boot/grub/grub.conf | awk -F'title ' '{print i++ " : " $2}' | grep ${KVersion} | grep -i -v debug | grep -i -v rescue | cut -d' ' -f1`
		if [ -z ${INS_OK} ]
		then
			echo "Sorry, install failed, please contact the author"
			exit
		fi
		sed -i "s/^default.*/default=${INS_OK}/" /boot/grub/grub.conf
	fi
fi

echo " "
echo "Installation is completed, now you can reboot the system. "
echo "You should check BBR after the rebooting using command: "
echo " "
echo "     sysctl -a|grep congestion_control"



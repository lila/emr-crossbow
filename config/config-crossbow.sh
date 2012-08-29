#!/bin/bash

function jsonval {
    temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop | cut -d ":" -f 2`
    echo ${temp##*|}
}

json=`cat /mnt/var/lib/info/instance.json`
prop='isMaster'
ismaster=`jsonval`

if [[ "$ismaster" -eq "true" ]]
then
	#
	# do actions only on master
	#
	echo "downloading crossbow source code"
	wget http://sourceforge.net/projects/bowtie-bio/files/crossbow/1.2.0/crossbow-1.2.0.zip/download
    	sudo unzip -d /opt download
	wget http://ftp-private.ncbi.nlm.nih.gov/sra/sdk/2.1.16/sratoolkit.2.1.16-centos_linux64.tar.gz
	sudo tar -zxvf sratoolkit.2.1.16-centos_linux64.tar.gz -C /opt
	echo '# crossbow configuration' >> /home/hadoop/.bashrc 
    	echo 'CROSSBOW_HOME=/opt/crossbow-1.2.0' >> /home/hadoop/.bashrc
    	echo 'export CROSSBOW_HOME' >> /home/hadoop/.bashrc

else
	#
	# do actions only on compute hosts
	#
	echo "downloading crossbow source code"
        wget http://sourceforge.net/projects/bowtie-bio/files/crossbow/1.2.0/crossbow-1.2.0.zip/download
        sudo unzip -d /opt download
	wget http://ftp-private.ncbi.nlm.nih.gov/sra/sdk/2.1.16/sratoolkit.2.1.16-centos_linux64.tar.gz
        sudo tar -zxvf sratoolkit.2.1.16-centos_linux64.tar.gz -C /opt
fi

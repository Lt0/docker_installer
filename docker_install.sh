#!/bin/sh

SEP="###############"

add_repo(){
	DOWNLOAD_ARCH=$1
	echo DOWNLOAD_ARCH is $DOWNLOAD_ARCH
	apt-get update
	apt-get install \
	    linux-image-extra-$(uname -r) \
	    linux-image-extra-virtual

	apt-get install \
	    apt-transport-https \
	    ca-certificates \
	    curl \
	    software-properties-common

	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

	apt-key fingerprint 0EBFCD88

	
	add-apt-repository "deb [arch=$DOWNLOAD_ARCH] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
}

add_armhf_for_aarch(){
	if [ -n "$(dpkg --print-foreign-architectures | grep armhf)" ]
	then
		echo armhf support has been dded to current system
	else
		dpkg --add-architecture armhf
	fi
}

install_docker(){
	apt-get update
	apt-get install docker-ce
}

test_docker(){
	docker run hello-world
}

select_download_url_for_arm(){
	if [ "$(cat /etc/*release* | grep -i xenial | wc -l)" -gt 0 ]
	then
		echo Downloading deb for xenial
		URL="https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/armhf/docker-ce_17.03.1~ce-0~ubuntu-xenial_armhf.deb"
	elif [ "$(cat /etc/*release* | grep -i trusty | wc -l)" -gt 0 ]
	then
		echo Downloading deb for trusty
		URL="https://download.docker.com/linux/ubuntu/dists/trusty/pool/stable/armhf/docker-ce_17.03.1~ce-0~ubuntu-trusty_armhf.deb"
	elif [ "$(cat /etc/*release* | grep -i yakkety | wc -l)" -gt 0 ]
	then
		echo Downloading deb for yakkety
		URL="https://download.docker.com/linux/ubuntu/dists/yakkety/pool/stable/armhf/docker-ce_17.03.1~ce-0~ubuntu-yakkety_armhf.deb"
	elif [ "$(cat /etc/*release* | grep -i zesty | wc -l)" -gt 0]
	then
		echo docker-ce is NOT support zesty
		exit
	else
		echo unknown system version
		exit
	fi

	wget -P /var/cache/apt/archives/ $URL
}

install_docker_aarch(){
	echo "There is no official docker-ce for aarch64 now(Thu Jun 22 15:19:06 UTC 2017)"
	echo Do you want to install armhf docker-ce for current system?
	echo NOTE: if you select y, this operation may BREAK the system. 
	echo Input y or n
	read ANSWER
	echo ANSWER is $ANSWER
	if [ "$ANSWER" = "y" ]
	then
		echo installing armhf docker-ce for aarch64 system
		add_armhf_for_aarch
		select_download_url_for_arm
		install_docker
		test_docker
		echo $SEP SSH TEST $SEP
		echo Please make sure you could still connect your system by ssh, if not, please instlal ssh with:
		echo apt-get install openssh-server
		echo $SEP REBOOT TEST $SEP
		echo Please reboot your system to make sure it could still boot up, if not, maybe you need to reinstall your system
	else
		echo exit for safe...
		exit
	fi
}

install_docker_amd(){
	echo installing docker-ce for x86_64
	add_repo amd64
	install_docker
	test_docker
}

install_docker_armhf(){
	echo installing docker-ce for armhf
	add_repo armhf
	install_docker
	test_docker
}

install_by_arch(){
	if [ "$ARCH" = "x86_64" ] 
	then
		install_docker_amd
	elif [ "$ARCH" = "armv7l" ]
	then
		install_docker_armhf
	elif [ "$ARCH" = "aarch64" ]
	then
		install_docker_aarch
	else
		echo $ARCH
		echo unknow arch, do nothing
		exit
	fi
}

show_help(){
echo "usage: $0 [option] [architecture]
options:
  -h | --help | help	show this help info
  -f | --force		install docker for a specific architecture
"
}


if [ -n "$1" ]
then
	case $1 in
		-f|--force)
			ARCH=$2
		;;
		*|-h|--help|help)
			show_help
			exit
		;;
	esac
else 
	ARCH=$(uname -p)
fi

install_by_arch

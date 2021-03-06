#!/bin/sh

OS=$(lsb_release -si)
ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
VER=$(lsb_release -sr)
APT=apt
TOPIC_IDENT="=> "

case $OS in
Ubuntu)
	OS="ubuntu"
	case $VER in
	16.04)
		VER_NAME="xenial"
		;;
	14.04)
		VER_NAME="trusty"
		;;
	12.04)
		VER_NAME="precise"
		;;
	*)
		echo "Unsupported Ubuntu ${VER}, BoxOS recommend used Debian Jessie or Ubuntu 16.04"
		;;
	esac
	;;
Debian)
	OS="debian"
	case $VER in
	9.*)
		VER_NAME="stretch"
		;;
	8.*)
		VER_NAME="jessie"
		;;
	7.*)
		VER_NAME="wheezy"
		;;
	*)
		echo "Unsupported Debian ${VER}, BoxOS recommend used Debian Jessie or Ubuntu 16.04"
		;;
	esac
	;;
*)
	echo "Unsupported distribution, BoxOS recommend used Debian Jessie or Ubuntu 16.04"
	;;
esac

DOCKER_REPO="deb https://apt.dockerproject.org/repo ${OS}-${VER_NAME} main"
DOCKER_COMPOSE_VERSION="1.13.0"
gpg_fingerprint="58118E89F3A912897C070ADBF76221572C52609D"
key_servers="
ha.pool.sks-keyservers.net
pgp.mit.edu
keyserver.ubuntu.com
"

echo "${TOPIC_IDENT}UPGRADE SYSTEM"
${APT} update && ${APT} upgrade -y
echo "${TOPIC_IDENT}INSTALL OS TOOLS"
${APT} install -y sudo apt-transport-https ca-certificates locales htop iotop iptraf
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
LANG=en_US.utf8

echo "${TOPIC_IDENT}KERNEL CONFIG"
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1 >> /dev/null 2>&1

echo "${TOPIC_IDENT}INSTALL DOCKER TOOLS"
for key_server in $key_servers ; do
        apt-key adv --keyserver hkp://${key_server}:80 --recv-keys ${gpg_fingerprint} && break
done
apt-key adv -k ${gpg_fingerprint} >/dev/null
mkdir -p /etc/apt/sources.list.d
echo ${DOCKER_REPO} > /etc/apt/sources.list.d/docker.list
sleep 3; ${APT} update -y; ${APT} install -y -q docker-engine
service docker start
docker run hello-world
curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/run.sh > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose

echo "${TOPIC_IDENT}INSTALL CTOP"
wget https://github.com/bcicen/ctop/releases/download/v0.6.1/ctop-0.6.1-linux-amd64 -O /usr/local/bin/ctop
chmod +x /usr/local/bin/ctop

echo "${TOPIC_IDENT}KERNEL TUNNING"
echo "${TOPIC_IDENT}${TOPIC_IDENT}IPV4 FORWARD"
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1 >> /dev/null 2>&1

echo "${TOPIC_IDENT}CUSTOM BASH"
echo "PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w \$ \[\033[00m\]'" > /root/.bash_profile
echo "alias ll='ls --color -l'" >> /root/.bash_profile
echo "CUSTOM MOTD"
cat > /etc/motd <<-END
  _                ____   _____
 | |              / __ \ / ____|
 | |__   _____  _| |  | | (___
 | '_ \ / _ \ \/ / |  | |\___ \
 | |_) | (_) >  <| |__| |____) |
 |_.__/ \___/_/\_\\\____/|_____/
 ============ Linux Containers
END

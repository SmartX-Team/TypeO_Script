#!/bin/bash

if [    -n "ifconfig | grep br-AP"   ]
then
	ifconfig br-AP down
	brctl delif br-AP veth1 && brctl delif br-AP wlx485d601fbca4
	brctl delbr br-AP
fi

if [    -n "ifconfig | grep br-IoT"   ]
then
        ifconfig br-IoT down
        ovs-vsctl del-port br-OF veth2 && ovs-vsctl del-port br-OF eno7
	ovs-vsctl del-br br-IoT
fi

if [    -z "ifconfig | grep eno4"   ]
then
	ifconfig eno7 up
	ifconfig eno3 up
	ifconfig eno4 up
fi

if [    -z "ifconfig | grep eno5"   ]
then
        ifconfig eno5 up
fi

if [    -z "ifconfig | grep eno6"   ]
then
        ifconfig eno6 up
fi


apt-get purge -y hostapd bridge-utils openvswitch-switch
apt-get update && apt-get install -y hostapd dnsmasq bridge-utils openvswitch-switch
#Type O의 동작을 위해 필요한 유틸들(Hostapd, Linux Bridge Util, OpenvSwitch)
#를 최신 버전으로 업데이트하기 위해서 지우고 다시 설치하는 과정을 수행

if [    -n "ifconfig -a | grep veth1"   ]
then
	ifconfig veth1 down&&ifconfig veth2 down
        ip link delete veth1 type veth
fi
#기존에 연결되어 있는 Veth1, Veth2를 지워주는 과정

ip link add name veth1 type veth peer name veth2
ifconfig veth1 up && ifconfig veth2 up
#Open vSwitch Bridge(Br-IoT)와 리눅스 Bridge(Br-AP)의 patching에 사용되는 Veth1, Veth2를 생성
echo -e "\nvirtual interfaces setting\n"
ifconfig

ovs-vsctl add-br br-IoT
ovs-vsctl add-port br-IoT veth2
#Patching에 사용되는 Veth2를 Br-IoT에 연결
ovs-vsctl add-port br-IoT eno3
ovs-vsctl add-port br-IoT eno7
ovs-vsctl add-port br-IoT eno4
ovs-vsctl add-port br-IoT eno5
ovs-vsctl add-port br-IoT eno6
ovs-vsctl set-controller br-IoT tcp:210.114.90.174:6633
#Task 3-1 인프라 슬라이싱을 위해 해당 Bridge를 ONOS Controller에 연결
echo -e "\novs switch setting\n"
ovs-vsctl show
#Open vSwitch로 만든 Bridge인 Br-IoT를 생성해주는 과정
#Br-IoT에 연결될 D(Data Plane) Interface들을 연결해주는 과정을 수행

brctl addbr br-AP
#리눅스 Bridge 생성
iw dev wlx485d601fbca4 set 4addr on
#<wlx485d601fbca4>는 무선 인터페이스의 장치 이름으로 사이트마다 다름
#해당 설정을 통해서 무선 인터페이스가 IPv4 주소를 가질 수 있도록 함
brctl addif br-AP veth1 && sudo brctl addif br-AP wlx485d601fbca4
echo -e "\nlinux bridge seting\n"
#무선 인터페이스와 Veth1를 Br-AP에 연결

sysctl -w net.ipv4.ip_forward=1
sleep 6
ifconfig br-AP up
ifconfig br-IoT up
ifconfig | grep br-AP
ifconfig | grep br-IoT

sed -i 's/no-resolv/no-resolv/g' /etc/dnsmasq.conf
sed -i 's/dhcp-range=interface:wlx485d601fbca4,192.168.50.81,192.168.55.99,12h/dhcp-range=wlx485d601fbca4,192.168.50.81,192.168.88.99,12h/g' /etc/dnsmasq.conf
sed -i 's/server=8.8.8.8/server=8.8.8.8/g' /etc/dnsmasq.conf
#dnsmasq(DHCP 서버)의 설정 파일
#DHCP IP pool은 Data Plane으로 여러 사이트에서 동시에 통신하는 상황을 고려 겹치지 않도록 설정 완료

echo -e "interface=wlx485d601fbca4
#bridge=br-AP
driver=nl80211
ssid=typeO_GIST
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=3
wpa_passphrase=typeo0070
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP"> ~/hostapd.conf
#무선 AP Daemon Hostapd 설정 파일
#Interface의 이름은 위에서 사이트 마다 다름
#AP의 SSID 역시 사이트마다 다르게 설정 완료


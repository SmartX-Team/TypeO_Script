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
#Type O�� ������ ���� �ʿ��� ��ƿ��(Hostapd, Linux Bridge Util, OpenvSwitch)
#�� �ֽ� �������� ������Ʈ�ϱ� ���ؼ� ����� �ٽ� ��ġ�ϴ� ������ ����

if [    -n "ifconfig -a | grep veth1"   ]
then
	ifconfig veth1 down&&ifconfig veth2 down
        ip link delete veth1 type veth
fi
#������ ����Ǿ� �ִ� Veth1, Veth2�� �����ִ� ����

ip link add name veth1 type veth peer name veth2
ifconfig veth1 up && ifconfig veth2 up
#Open vSwitch Bridge(Br-IoT)�� ������ Bridge(Br-AP)�� patching�� ���Ǵ� Veth1, Veth2�� ����
echo -e "\nvirtual interfaces setting\n"
ifconfig

ovs-vsctl add-br br-IoT
ovs-vsctl add-port br-IoT veth2
#Patching�� ���Ǵ� Veth2�� Br-IoT�� ����
ovs-vsctl add-port br-IoT eno3
ovs-vsctl add-port br-IoT eno7
ovs-vsctl add-port br-IoT eno4
ovs-vsctl add-port br-IoT eno5
ovs-vsctl add-port br-IoT eno6
ovs-vsctl set-controller br-IoT tcp:210.114.90.174:6633
#Task 3-1 ������ �����̽��� ���� �ش� Bridge�� ONOS Controller�� ����
echo -e "\novs switch setting\n"
ovs-vsctl show
#Open vSwitch�� ���� Bridge�� Br-IoT�� �������ִ� ����
#Br-IoT�� ����� D(Data Plane) Interface���� �������ִ� ������ ����

brctl addbr br-AP
#������ Bridge ����
iw dev wlx485d601fbca4 set 4addr on
#<wlx485d601fbca4>�� ���� �������̽��� ��ġ �̸����� ����Ʈ���� �ٸ�
#�ش� ������ ���ؼ� ���� �������̽��� IPv4 �ּҸ� ���� �� �ֵ��� ��
brctl addif br-AP veth1 && sudo brctl addif br-AP wlx485d601fbca4
echo -e "\nlinux bridge seting\n"
#���� �������̽��� Veth1�� Br-AP�� ����

sysctl -w net.ipv4.ip_forward=1
sleep 6
ifconfig br-AP up
ifconfig br-IoT up
ifconfig | grep br-AP
ifconfig | grep br-IoT

sed -i 's/no-resolv/no-resolv/g' /etc/dnsmasq.conf
sed -i 's/dhcp-range=interface:wlx485d601fbca4,192.168.50.81,192.168.55.99,12h/dhcp-range=wlx485d601fbca4,192.168.50.81,192.168.88.99,12h/g' /etc/dnsmasq.conf
sed -i 's/server=8.8.8.8/server=8.8.8.8/g' /etc/dnsmasq.conf
#dnsmasq(DHCP ����)�� ���� ����
#DHCP IP pool�� Data Plane���� ���� ����Ʈ���� ���ÿ� ����ϴ� ��Ȳ�� ��� ��ġ�� �ʵ��� ���� �Ϸ�

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
#���� AP Daemon Hostapd ���� ����
#Interface�� �̸��� ������ ����Ʈ ���� �ٸ�
#AP�� SSID ���� ����Ʈ���� �ٸ��� ���� �Ϸ�


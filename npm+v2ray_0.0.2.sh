#/bin/bash
#安装BBR模块函数
rebootVps(){
while true
do
echo  
read -p $(echo -e "\e[1;33mBBR模块已启用,需要重启vps使BBR生效,重启输入y不重启输入n[y/n]:\e[0m") actiobbb
case "$actiobbb" in
 yes|y|Yes|YES|Y)
     sudo reboot;;
       n|no|NO|N)
	 menu
    break
	;;
     *)
    echo -e "\e[1;31m喔!!!请输入正确的选项Y或n\e[0m" ;;
esac
done
}
installBBR(){
while true
do
echo  
read -p $(echo -e "\e[1;33m确定安装BBR?[y/n]:\e[0m") action
case "$action" in
 yes|y|Yes|YES|Y)
     NEED_BBR=y;;
 n|no|NO|N)
    menu
    break
	;;
 *)
    echo -e "\e[1;31m嘿!!!请输入正确的选项Y或n\e[0m" ;;
esac
	
	if [[ -s /etc/selinux/config ]] && grep 'SELINUX=enforcing' /etc/selinux/config; then
		sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
		setenforce 0
	fi
	if [[ "$NEED_BBR" != "y" ]]; then
		INSTALL_BBR=false
		return
	fi
	result=$(lsmod | grep bbr)
	if [[ "$result" != "" ]]; then
		echo -e "\e[1;34mBBR模块已安装-不需要再安装,6秒后自动返回主菜单\e[0m"
		sleep 6
        menu
		INSTALL_BBR=false
		return
	fi
	res=$(hostnamectl | grep -i openvz)
	if [[ "$res" != "" ]]; then
		echo -e "\e[1;34mopenvz机器，跳过安装,6秒后自动返回主菜单\e[0m"
		sleep 6
        menu
		INSTALL_BBR=false
		return
	fi
	sudo apt update
	sudo apt upgrade -y
	sudo chmod 666 /etc/sysctl.conf
	sudo echo "net.core.default_qdisc=fq" >>/etc/sysctl.conf
	sudo echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.conf
	sudo chmod 644 /etc/sysctl.conf
	sudo sysctl -p
	result=$(lsmod | grep bbr)
	if [[ "$result" != "" ]]; then
        # echo -e "\e[1;31mBBR模块已启用-->>如果还没有重启，请退出脚本后输入sudo reboot重启vps使BBR生效\e[0m"
		rebootVps
		INSTALL_BBR=false
		return
	fi
	echo -e "\e[1;34m 安装BBR模块...\e[0m"
	if [[ "$PMT" == "yum" ]]; then
		if [[ "$V6_PROXY" == "" ]]; then
			rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
			rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
			$CMD_INSTALL --enablerepo=elrepo-kernel kernel-ml
			$CMD_REMOVE kernel-3.*
			sudo grub2-set-default 0
			sudo echo "tcp_bbr" >>/etc/modules-load.d/modules.conf
			INSTALL_BBR=true
		fi
	else
		$CMD_INSTALL --install-recommends linux-generic-hwe-16.04
		sudo grub-set-default 0
		sudo chmod 666 /etc/modules
		sudo echo "tcp_bbr" >>/etc/modules-load.d/modules.conf
		sudo chmod 644 /etc/modules
		INSTALL_BBR=true
	fi
done
}
#docker安装阶段
installdocker(){
if [ -f /usr/local/bin/docker-compose ];then
  echo -e "\e[1;36mDokcer和docker-compose已安装-不需要再安装\e[0m"
  echo 安装上的docker版本是$(docker -v)
else
sudo apt update
sudo apt upgrade -y
wget -qO- get.docker.com | bash
docker -v
comNewv=`wget --no-check-certificate -qO- https://api.github.com/repos/docker/compose/tags | grep 'name' | cut -d\" -f4 | head -1 | cut -b 2-`
sudo curl -L "https://github.com/docker/compose/releases/download/v$comNewv/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

#启动docker：
sudo systemctl start docker

#设置docker开机启动：
sudo systemctl enable docker
echo 安装上的docker版本是$(docker -v)
fi
sleep 6
menu
}
#NPM安装
#NPM安装
npm_install(){
while true
do
lsof -n -P -i :443 | grep LISTEN
if [ $? -eq 0 ];then
        echo -e "\e[1;36m443端口被占用，请释放443端口再来安装,因npm需要,6秒后退出\e[0m"
        sleep 3
		break
fi
lsof -n -P -i :80 | grep LISTEN
if [ $? -eq 0 ];then
       echo -e "\e[1;36m80端口被占用，请释放80端口再来安装,因npm需要,6秒后跳回主菜单\e[0m"
       sleep 3
	   break
fi
mkdir -p docker_data/npm/dada docker_data/npm/letsencrypt
cat > ./docker_data/npm/docker-compose.yml <<-EOF
version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
	EOF
sleep 1
docker-compose -f ./docker_data/npm/docker-compose.yml up -d
wait
echo -e "\e[1;36mNPM安装结束\e[0m"
break
done
sleep 4
menu
}
#v2ray安装
re_mpec(){
sudo rm -rf ./oneuuid.pec >/dev/null 2>&1
sudo rm -rf ./pahonevless.pec >/dev/null 2>&1
sudo rm -rf ./pahonevmess.pec >/dev/null 2>&1
sudo rm -rf ./pahtwovless.pec >/dev/null 2>&1
sudo rm -rf ./pahtwovmess.pec >/dev/null 2>&1
sudo rm -rf ./twouuid.pec >/dev/null 2>&1
}
installv2ray(){
re_mpec
if [ -f /etc/systemd/system/v2ray.service ];then
  echo -e "\e[1;36mv2ray已安装-请卸载后再安装\e[0m"
else
sudo apt update
sudo apt install uuid-runtime
sudo apt install net-tools
sleep 2
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
sleep 1
sudo systemctl enable v2ray
ipgo=$(ifconfig | sed -n '/^br-.*:/{n;p}' | awk -F'[ ]+' '{print $3}')
echo -e "\e[1;38m接下来开始修改v2ray配置文件:\e[0m"
echo ""
while true
 do
echo -e "\e[1;36m         v2ray的UUID个数设置\e[0m"
echo ""	     
	cat <<-EOF
 	A  默认给路径1和路径2自动分配10个UUID
 	B  添加更多的UUID
	EOF
	echo ""
	read -p $(echo -e "\e[1;33m请输入操作选项后继续|A|B|:\e[0m") dor_zoo
	case "$dor_zoo" in
         a|A)
         echo -e "\e[1;33m你选择了保持默认10个:\e[0m"
         break
         ;;
         b|B)
         while true
           do
          read -p $(echo -e "\e[1;33m路径1请输入还需要新增的UUID个数2至30:\e[0m") uid_nwe
          emp_est=$(echo $uid_nwe | grep -E '[ ]' >/dev/null;echo $? )
          if [ "${uid_nwe}" == "" ]; then
                    echo "输入不能为空"  
           elif [[ "$uid_nwe" == *[aA-zZ]* ]]; then
                    echo "请输入数字。"   
           elif [[ "$uid_nwe" == *['!'@#\$%^\&*()_+]* ]]; then
                     echo  "输入的不能包含特殊符号。"                   
           elif [ "$uid_nwe" -gt "30" ]; then
                    echo "最多只能输入30"      
           elif [[ "$uid_nwe" == "1" ]]; then
                    echo "至少输入2"
           elif [[ "$emp_est" == "0" ]]; then
                    echo "输入的不能包含空格。" 
           elif [[ "$uid_nwe" == "0" ]]; then
                    echo "至少输入2！！！"                              
           else
                break                    
           fi

           done
           
         while true
           do
           echo ""
          read -p $(echo -e "\e[1;33m路径2请输入还需要新增的UUID个数2至30:\e[0m") diu_nre
          emrp_est=$(echo $diu_nre | grep -E '[ ]' >/dev/null;echo $? )
          if [ "${diu_nre}" == "" ]; then
                    echo "输入不能为空"  
           elif [[ "$diu_nre" == *[aA-zZ]* ]]; then
                    echo "请输入数字。"  
           elif [[ "$diu_nre" == *['!'@#\$%^\&*()_+]* ]]; then 
                    echo  "输入的不能包含特殊符号。"                                                 
           elif [ "$diu_nre" -gt "30" ]; then
                    echo "最多只能输入30"      
           elif [[ "$diu_nre" == "1" ]]; then
                    echo "至少输入2"
           elif [[ "$emrp_est" == "0" ]]; then
                    echo "输入的不能包含空格。" 
           elif [[ "$diu_nre" == "0" ]]; then
                    echo "至少输入2！！！"                                         
           else
                break                    
           fi

           done

for i in $(seq -w $uid_nwe)
do
    abc_one="`uuidgen`"
    echo "$abc_one"
cat >> ./pahonevless.pec <<EOF          
          {
            "id": "$abc_one"
          },
EOF
cat >> ./pahonevmess.pec <<EOF
          {
            "id": "$abc_one",
	    "alterId": 0
          },
EOF
echo $abc_one | tee -a ./oneuuid.pec
done
for i in $(seq -w $diu_nre)
do
    abc_two="`uuidgen`"
    echo "$abc_two"
cat >> ./pahtwovless.pec <<EOF          
          {
            "id": "$abc_two"
          },
EOF
cat >> ./pahtwovmess.pec <<EOF          
          {
            "id": "$abc_two",
	    "alterId": 0
          },
EOF
echo $abc_two | tee -a ./twouuid.pec
done
hun_gryonev=$(cat ./pahonevless.pec)
hun_gryonem=$(cat ./pahonevmess.pec)
hun_grytwov=$(cat ./pahtwovless.pec)
hun_grytwom=$(cat ./pahtwovmess.pec)
         
         break
         ;;
	 *)
	 clear
	 echo ""
	 echo -e "\e[1;31m输入错误提示!!!请输入正确选项|A|B|\e[0m";;
         esac
         
done
sleep 1
#vless路径
randos_a=$[$RANDOM%4+10]
path_a=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $randos_a | head -n 1)
randos_b=$[$RANDOM%4+10]
path_b=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $randos_b | head -n 1)
#vmess路径
randos_c=$[$RANDOM%4+10]
path_c=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $randos_c | head -n 1)
randos_d=$[$RANDOM%4+10]
path_d=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $randos_d | head -n 1)
#多UUIDvless与vmess共用，共10组。
uuid_a="`uuidgen`"
uuid_b="`uuidgen`"
uuid_c="`uuidgen`"
uuid_d="`uuidgen`"
uuid_e="`uuidgen`"
uuid_f="`uuidgen`"
uuid_g="`uuidgen`"
uuid_h="`uuidgen`"
uuid_i="`uuidgen`"
uuid_j="`uuidgen`"
echo -e "\e[1;33m变量定义完成，开始配置config.json\e[0m"
sleep 1
cat > /usr/local/etc/v2ray/config.json <<EOF
{
    "inbounds": [
      {
      "port": 29881,
      "listen":"$ipgo",
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "$uuid_a"
          },
          {
            "id": "$uuid_b"
          },
          {
            "id": "$uuid_c"
          },
          {
            "id": "$uuid_d"
          },
          $hun_gryonev
          {
            "id": "$uuid_e"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
	    "security": "none",
        "wsSettings": {
        "path": "/$path_a"
        }
      }
    },
    {
      "port": 29882,
      "listen":"$ipgo",
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "$uuid_f"
          },
          {
            "id": "$uuid_g"
          },
          {
            "id": "$uuid_h"
          },
          {
            "id": "$uuid_i"
          },
          $hun_grytwov
          {
            "id": "$uuid_j"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
	    "security": "none",
        "wsSettings": {
        "path": "/$path_b"
        }
      }
    },
    {
      "port": 29883,
      "listen": "$ipgo",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid_a",
	    "alterId": 0
          },
          {
            "id": "$uuid_b",
	    "alterId": 0
          },
          {
            "id": "$uuid_c",
	    "alterId": 0
          },
          {
            "id": "$uuid_d",
	    "alterId": 0
          },
          $hun_gryonem
          {
            "id": "$uuid_e",
	    "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/$path_c"
        }
      }
    },
    {
      "port": 29884,
      "listen": "$ipgo",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid_f",
	    "alterId": 0
          },
          {
            "id": "$uuid_g",
	     "alterId": 0
          },
          {
            "id": "$uuid_h",
	    "alterId": 0
          },
          {
            "id": "$uuid_i",
	     "alterId": 0
          },
          $hun_grytwom
          {
            "id": "$uuid_j",
	    "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/$path_d"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ],
  "transport": {},
  "stats": {},
  "reverse": {}
}
EOF
echo "VPS内部docker网卡IP: $ipgo"
echo "安全：tls"
echo "传输：ws"
echo "协议：vmess"
echo ""
echo -e "\e[1;33mv2ray安装完成，路径与UUID信息保存在脚本旁边的v2ray_by.txt文档里面,请及时下载到本地系统里面去\e[0m"
echo ""
test  -e ./oneuuid.pec && onelinu=$(cat ./oneuuid.pec )
test  -e ./twouuid.pec && twoliun=$(cat ./twouuid.pec )
cat > v2ray_by.txt <<EOF
===============================================
VPS内部docker网卡IP: $ipgo
------------------------------------------------以下是账号的路径和uuid。
vless参数
路径1: /$path_a 与以下UUID是一组
UUID: $uuid_a
UUID: $uuid_b
UUID: $uuid_c
UUID: $uuid_d
UUID: $uuid_e
$onelinu
路径2: /$path_b 与以下UUID是一组
UUID: $uuid_f
UUID: $uuid_g
UUID: $uuid_h
UUID: $uuid_i
UUID: $uuid_j
$twoliun
安全：tls
传输：ws
协议：vless
-----------------------------------------------
vmess参数
路径1: /$path_c  与以下UUID是一组
UUID: $uuid_a
UUID: $uuid_b
UUID: $uuid_c
UUID: $uuid_d
UUID: $uuid_e
$onelinu
路径2: /$path_d  与以下UUID是一组
UUID: $uuid_f
UUID: $uuid_g
UUID: $uuid_h
UUID: $uuid_i
UUID: $uuid_j
$twoliun
安全：tls
传输：w
协议：vmess
-----------------------------------------------
EOF
re_mpec
sudo systemctl start v2ray
sleep 1
sudo systemctl status v2ray --no-pager
echo -e "\e[1;33m7秒后跳转到主菜单\e[0m"
sleep 7
menu
fi
}
#swap虚拟缓存分区，缓解vps内存小不够用的问题
mkswapyu(){
echo $(dd if=/dev/zero of=/mnt/swap bs=1M count=4096)
wait
echo "swap分区结束,共4GB"
test -e /mnt/swap &&  chmod 600 /mnt/swap || error
echo $(mkswap /mnt/swap)
echo $(swapon /mnt/swap)
[ -z "$(swapon -s | grep /mnt/swap)" ] && echo "swap分区没有挂载成功"
echo '/mnt/swap   swap   swap   defaults  0   0' | tee -a /etc/fstab
[ -z "$(mount -a)" ] && echo "swap创建成功" || echo "swap创建没有成功"
sleep 6
menu
}
ctrldocker(){
#删除容器停止容器重启容器功能
clear
while true
do
echo -e "\e[1;33m        以下是docker容器管理功能\e[0m"
echo  
cat <<-EOF
 	A	停止容器
 	B	启动容器
 	C	重启容器
 	D	删除容器
 	E	查看容器状态
 	F	容器加入开机自启
 	X	退出容器管理
	EOF
read -p $(echo -e "\e[1;33m请输入想要的操作选项|A|B|C|D|E|F|X|:\e[0m") actiokk
clear
case "$actiokk" in
     a|A)
	 clear
	 sudo docker ps && echo -e "\e[1;34m以上显示系统中在运行的容器状态(啥都没有显示,代表没有处于启动的容器,请按enter键返回)\e[0m"  
	 read -p $(echo -e "\e[1;33m请输入以上要停止的容器ID例如：d6108d884eb4:\e[0m") actiopo
     sudo docker stop $actiopo
	 ;;
     b|B)
	 clear
	 sudo docker ps -a | grep Exit
	 echo -e "\e[1;34m以上显示的是系统中处于停止的容器(啥都没有显示,代表没有处于停止的容器,请按enter键返回)\e[0m" 
	 read -p $(echo -e "\e[1;33m请输入以上要启动的容器ID例如：d6108d884eb4:\e[0m") actiod
     sudo docker start $actiod
	 ;;
	 c|C)
	 clear
	 sudo docker ps && echo -e "\e[1;34m以上显示系统中在运行的容器状态(啥都没有显示,代表没有处于启动的容器,请按enter键返回)\e[0m" 
	 read -p $(echo -e "\e[1;33m请输入以上要重新启动的容器ID例如：d6108d884eb4:\e[0m") actiof
	 sudo docker restart $actiof
	 ;;
     d|D)
	 clear
	 sudo docker ps -a && echo -e "\e[1;34m以上显示系统中所有的容器状态(啥都没有显示,代表没有容器,请按enter键返回)\e[0m"  
	 read -p $(echo -e "\e[1;33m请输入以上要删除的容器ID例如：d6108d884eb4:\e[0m") actiog
	 sudo docker stop $actiog && sudo docker rm $actiog
     ;;
	 e|E)
     sudo docker ps && echo -e "\e[1;34m以上显示是系统中正在运行的容器(啥都没有显示,代表没有处于启动的容器)\e[0m" 
	 sudo docker ps -a && echo -e "\e[1;34m以上显示的是系统中所有容器状态，启动或没启动的都在(啥都没有显示,代表没有容器)\e[0m"
	 ;;
	 f|F)
	 clear
	 sudo docker ps && echo -e "\e[1;34m以上显示系统中在运行的容器状态(啥都没有显示,代表没有处于启动的容器,请按enter键返回)\e[0m"  
	 read -p $(echo -e "\e[1;33m请输入以上要加入开机自启的容器ID例如：d6108d884eb4:\e[0m") actiopu
     sudo docker update --restart=always $actiopu
	 ;;
	 x|X)
	 menu
	 break;;
	 *)
	 echo -e "\e[1;31m输入错误提示!!!请输入正确选项|A|B|C|D|E|F|X|\e[0m";;

esac
done
}
ctrlvy(){
#管理v2ray
clear
while true
do
echo -e "\e[1;33m        以下是v2ray管理功能\e[0m"
echo  
cat <<-EOF
 	A	启动v2ray
 	B	重启v2ray
 	C	查看状态v2ray
 	D	停止v2ray
 	E	卸载v2ray
 	X	退出v2ray管理
	EOF
read -p $(echo -e "\e[1;33m请输入想要的操作选项|A|B|C|D|X|:\e[0m") actiokn
clear
case "$actiokn" in
     a|A)
	 clear
	 #启动
      sudo systemctl start v2ray
	  sudo systemctl status v2ray --no-pager
	  echo -e "\e[1;38m红色代表启动失败，绿色代表启动成功:\e[0m"
      sleep 4
	  clear
	 ;;
     b|B)
	 clear
	 #重启
	  sudo systemctl restart v2ray
	  sudo systemctl status v2ray --no-pager
	  echo -e "\e[1;38m红色代表启动失败，绿色代表启动成功:\e[0m"
      sleep 4
	  clear
	 ;;
	 c|C)
	 clear
	 #查看状态
	 sudo systemctl status v2ray --no-pager
	 echo -e "\e[1;38m红色代表启动失败，绿色代表启动成功:\e[0m"
	 sleep 6
	 clear
	 ;;
     d|D)
	 clear
	 #停止
	 sudo systemctl stop v2ray
	 sudo systemctl status v2ray --no-pager
	 echo -e "\e[1;38m红色代表启动失败，绿色代表启动成功:\e[0m"
	 sleep 4
	 clear
     ;;
     e|E)
	 clear
	 #卸载
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) --remove
     sudo systemctl disable v2ray.service
	 rm  /usr/local/etc/v2ray/config.json
     sudo systemctl status v2ray --no-pager
	 echo -e "\e[1;38m卸载后记得输入reboot重启一下vps:\e[0m"
	 sleep 4
	 clear
     ;;
	 x|X)
	 menu
	 break
	 ;;
	 *)
	 echo -e "\e[1;31m输入错误提示!!!请输入正确选项|A|B|C|D|E|X|\e[0m";;

esac
done
}
ctrlswap(){
#管理swap分区
clear
while true
do
echo -e "\e[1;33m        以下是swap分区管理功能\e[0m"
echo  
cat <<-EOF
 	A	 重新挂载swap分区
 	B	 !!!占位而已
 	C	 !!!占位而已
 	D	 !!!占位而已
 	E	 !!!占位而已
 	X	退出swap分区管理
	EOF
echo -e "\e[1;33m可能你会遇见报错,直接按CTRL+C键终止掉后就不要来用这个功能了。\e[0m"
read -p $(echo -e "\e[1;33m请输入想要的操作选项|A|B|C|D|X|:\e[0m") actiokm
clear
case "$actiokm" in
     a|A)
	 clear
	 # 重新挂载swap分区
test -e /mnt/swap &&  chmod 600 /mnt/swap || error
echo $(mkswap /mnt/swap)
echo $(swapon /mnt/swap)
[ -z "$(swapon -s | grep /mnt/swap)" ] && echo "swap分区没有挂载成功"
echo '/mnt/swap   swap   swap   defaults  0   0' | tee -a /etc/fstab
[ -z "$(mount -a)" ] && echo "swap创建成功" || echo "swap创建没有成功"
      sleep 3
	 ;;
     b|B)
	 clear
	 # 
	  echo -e "\e[1;38m!!!占位而已:\e[0m"
      sleep 3
	 ;;
	 c|C)
	 clear
	 # 
	 echo -e "\e[1;38m!!!占位而已:\e[0m"
	 ;;
     d|D)
	 clear
	 # 
	 echo -e "\e[1;38m!!!占位而已:\e[0m"
     ;;
     e|E)
	 clear
	 # 
	 echo -e "\e[1;38哈哈!!!占位而已,啥都没有写:\e[0m"
     ;;
	 x|X)
	 menu
	 break;;
	 *)
	 echo -e "\e[1;31m输入错误提示!!!请输入正确选项|A|B|C|D|X|\e[0m";;

esac
done

}
configinf(){
ver="1.0.2"

trap _exit INT QUIT TERM

_red() {
    printf '\033[0;31;31m%b\033[0m' "$1"
}

_green() {
    printf '\033[0;31;32m%b\033[0m' "$1"
}

_yellow() {
    printf '\033[0;31;33m%b\033[0m' "$1"
}

_blue() {
    printf '\033[0;31;36m%b\033[0m' "$1"
}

_exists() {
    local cmd="$1"
    if eval type type > /dev/null 2>&1; then
        eval type "$cmd" > /dev/null 2>&1
    elif command > /dev/null 2>&1; then
        command -v "$cmd" > /dev/null 2>&1
    else
        which "$cmd" > /dev/null 2>&1
    fi
    local rt=$?
    return ${rt}
}

_exit() {
    _red "\n检测到退出操作，脚本终止！\n"
    # clean up
    rm -fr speedtest.tgz speedtest-cli benchtest_*
    exit 1
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print $0}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

speed_test() {
    local nodeName="$2"
    [ -z "$1" ] && ./speedtest-cli/speedtest --progress=no --accept-license --accept-gdpr > ./speedtest-cli/speedtest.log 2>&1 || \
    ./speedtest-cli/speedtest --progress=no --server-id=$1 --accept-license --accept-gdpr > ./speedtest-cli/speedtest.log 2>&1
    if [ $? -eq 0 ]; then
        local dl_speed=$(awk '/Download/{print $3" "$4}' ./speedtest-cli/speedtest.log)
        local up_speed=$(awk '/Upload/{print $3" "$4}' ./speedtest-cli/speedtest.log)
        local latency=$(awk '/Latency/{print $2" "$3}' ./speedtest-cli/speedtest.log)
        if [[ -n "${dl_speed}" && -n "${up_speed}" && -n "${latency}" ]]; then
            printf "\033[0;33m%-18s\033[0;32m%-18s\033[0;31m%-20s\033[0;36m%-12s\033[0m\n" " ${nodeName}" "${up_speed}" "${dl_speed}" "${latency}"
        fi
    fi
}

io_test() {
    (LANG=C dd if=/dev/zero of=benchtest_$$ bs=512k count=$1 conv=fdatasync && rm -f benchtest_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}
    do
        [ "${size}" == "0" ] && size_t=0 || size_t=`echo ${size:0:${#size}-1}`
        [ "`echo ${size:(-1)}`" == "K" ] && size=0
        [ "`echo ${size:(-1)}`" == "M" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
        [ "`echo ${size:(-1)}`" == "T" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
        [ "`echo ${size:(-1)}`" == "G" ] && size=${size_t}
        total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
    done
    echo ${total_size}
}

check_virt(){
    _exists "dmesg" && virtualx="$(dmesg 2>/dev/null)"
    if _exists "dmidecode"; then
        sys_manu="$(dmidecode -s system-manufacturer 2>/dev/null)"
        sys_product="$(dmidecode -s system-product-name 2>/dev/null)"
        sys_ver="$(dmidecode -s system-version 2>/dev/null)"
    else
        sys_manu=""
        sys_product=""
        sys_ver=""
    fi
    if   grep -qa docker /proc/1/cgroup; then
        virt="Docker"
    elif grep -qa lxc /proc/1/cgroup; then
        virt="LXC"
    elif grep -qa container=lxc /proc/1/environ; then
        virt="LXC"
    elif [[ -f /proc/user_beancounters ]]; then
        virt="OpenVZ"
    elif [[ "${virtualx}" == *kvm-clock* ]]; then
        virt="KVM"
    elif [[ "${cname}" == *KVM* ]]; then
        virt="KVM"
    elif [[ "${cname}" == *QEMU* ]]; then
        virt="KVM"
    elif [[ "${virtualx}" == *"VMware Virtual Platform"* ]]; then
        virt="VMware"
    elif [[ "${virtualx}" == *"Parallels Software International"* ]]; then
        virt="Parallels"
    elif [[ "${virtualx}" == *VirtualBox* ]]; then
        virt="VirtualBox"
    elif [[ -e /proc/xen ]]; then
        if grep -q "control_d" "/proc/xen/capabilities" 2>/dev/null; then
            virt="Xen-Dom0"
        else
            virt="Xen-DomU"
        fi
    elif [ -f "/sys/hypervisor/type" ] && grep -q "xen" "/sys/hypervisor/type"; then
        virt="Xen"
    elif [[ "${sys_manu}" == *"Microsoft Corporation"* ]]; then
        if [[ "${sys_product}" == *"Virtual Machine"* ]]; then
            if [[ "${sys_ver}" == *"7.0"* || "${sys_ver}" == *"Hyper-V" ]]; then
                virt="Hyper-V"
            else
                virt="Microsoft Virtual Machine"
            fi
        fi
    else
        virt="Dedicated"
    fi
}
ipv4_info() {
    local org="$(wget -q -T10 -O- ipinfo.io/org)"
    local city="$(wget -q -T10 -O- ipinfo.io/city)"
    local country="$(wget -q -T10 -O- ipinfo.io/country)"
    local region="$(wget -q -T10 -O- ipinfo.io/region)"
    if [[ -n "$org" ]]; then
        echo " ASN组织           : $(_blue "$org")"
    fi
    if [[ -n "$city" && -n "country" ]]; then
        echo " 位置              : $(_blue "$city / $country")"
    fi
    if [[ -n "$region" ]]; then
        echo " 地区              : $(_yellow "$region")"
    fi
    if [[ -z "$org" ]]; then
        echo " 地区              : $(_red "无法获取ISP信息")"
    fi
}

print_intro() {
    echo "--------------------- A Bench Script By Misaka No --------------------"
    echo "                     Blog: https://owo.misaka.rest                    "
    echo "版本号：v$ver"
    echo "更新日志：$changeLog"
}

# Get System information
get_system_info() {
    cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    cores=$( awk -F: '/processor/ {core++} END {print core}' /proc/cpuinfo )
    freq=$( awk -F'[ :]' '/cpu MHz/ {print $4;exit}' /proc/cpuinfo )
    ccache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    tram=$( LANG=C; free -m | awk '/Mem/ {print $2}' )
    uram=$( LANG=C; free -m | awk '/Mem/ {print $3}' )
    swap=$( LANG=C; free -m | awk '/Swap/ {print $2}' )
    uswap=$( LANG=C; free -m | awk '/Swap/ {print $3}' )
    up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime )
    if _exists "w"; then
        load=$( LANG=C; w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
    elif _exists "uptime"; then
        load=$( LANG=C; uptime | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
    fi
    opsy=$( get_opsy )
    arch=$( uname -m )
    if _exists "getconf"; then
        lbit=$( getconf LONG_BIT )
    else
        echo ${arch} | grep -q "64" && lbit="64" || lbit="32"
    fi
    kern=$( uname -r )
    disk_size1=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker|snapd' | awk '{print $2}' ))
    disk_size2=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker|snapd' | awk '{print $3}' ))
    disk_total_size=$( calc_disk "${disk_size1[@]}" )
    disk_used_size=$( calc_disk "${disk_size2[@]}" )
    tcpctrl=$( sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}' )
}
# Print System information
print_system_info() {
    if [ -n "$cname" ]; then
        echo " CPU 型号          : $(_blue "$cname")"
    else
        echo " CPU 型号          : $(_blue "无法检测到CPU型号")"
    fi
    echo " CPU 核心数        : $(_blue "$cores")"
    if [ -n "$freq" ]; then
        echo " CPU 频率          : $(_blue "$freq MHz")"
    fi
    if [ -n "$ccache" ]; then
        echo " CPU 缓存          : $(_blue "$ccache")"
    fi
    echo " 硬盘空间          : $(_yellow "$disk_total_size GB") $(_blue "($disk_used_size GB 已用)")"
    echo " 内存              : $(_yellow "$tram MB") $(_blue "($uram MB 已用)")"
    echo " Swap              : $(_blue "$swap MB ($uswap MB 已用)")"
    echo " 系统在线时间      : $(_blue "$up")"
    echo " 负载              : $(_blue "$load")"
    echo " 系统              : $(_blue "$opsy")"
    echo " 架构              : $(_blue "$arch ($lbit Bit)")"
    echo " 内核              : $(_blue "$kern")"
    echo " TCP加速方式       : $(_yellow "$tcpctrl")"
    echo " 虚拟化架构        : $(_blue "$virt")"
}


print_end_time() {
    end_time=$(date +%s)
    time=$(( ${end_time} - ${start_time} ))
    if [ ${time} -gt 60 ]; then
        min=$(expr $time / 60)
        sec=$(expr $time % 60)
        echo " 总共花费        : ${min} 分 ${sec} 秒"
    else
        echo " 总共花费        : ${time} 秒"
    fi
    date_time=$(date +%Y-%m-%d" "%H:%M:%S)
    echo " 时间          : $date_time"
}

! _exists "wget" && _red "Error: wget command not found.\n" && exit 1
! _exists "free" && _red "Error: free command not found.\n" && exit 1
start_time=$(date +%s)
get_system_info
check_virt
clear
print_intro
next
print_system_info
next
ipv4_info
next
print_end_time
next
echo -e "\e[1;33m将查询出来的信息用鼠标复制保存到文档中去，以上信息9秒后消失\e[0m"
sleep 9
menu
}
#菜单打印函数定义
menu(){
clear
echo -e "\e[1;33m        v2ray配置信息会保存在脚步旁边的v2ray_by.txt文档中\e[0m"
echo 
cat <<-EOF
 	01	安装BBR模块
 	02	安装Docker软件
 	03	安装NPM软件
 	04	安装v2ray
 	05	退出脚本
 	06	swap分区
 	07	管理docker容器
 	08	管理v2ray
 	09	管理swap分区
 	10	vps配置信息
	EOF
}
menu
while true
do
#用户选择需要操作的内容 
echo $""
read -p $(echo -e "\e[1;31m------>>请输入您的选项(若菜单没有显示,请按下enter键):\e[0m") action
clear
menu	
case $action in 
	11|help)
	menu
	;;
	01)
	installBBR
	;;
	02)
	installdocker
	;;
	03)
	npm_install
	;;
	04)
	installv2ray
	;;
	05)
	exit
	;;
	06)
	mkswapyu
	;;
	07)
	ctrldocker
	;;
	08)
	ctrlvy
	;;
	09)
	ctrlswap
	;;
	10)
	configinf
	;;

esac
done


















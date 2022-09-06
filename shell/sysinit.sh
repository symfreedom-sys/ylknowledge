#/bin/bash

# 系统内核优化,网络优化
if ! grep "net.ipv4.route.gc_timeout" /etc/sysctl.conf &>/dev/null; then
 cat >> /etc/sysctl.conf << EOF
 net.core.netdev_max_backlog = 32768
 net.core.somaxconn = 32768
 net.core.wmem_default = 8388608
 net.core.rmem_default = 8388608
 net.core.rmem_max = 16777216
 net.core.wmem_max = 16777216
 net.ipv4.ip_local_port_range = 1024 65000
 net.ipv4.route.gc_timeout = 100
 net.ipv4.tcp_fin_timeout = 30
 net.ipv4.tcp_keepalive_time = 1200
 net.ipv4.tcp_timestamps = 0
 net.ipv4.tcp_synack_retries = 2
 net.ipv4.tcp_syn_retries = 2
 net.ipv4.tcp_tw_recycle = 1
 net.ipv4.tcp_tw_reuse = 1
 net.ipv4.tcp_mem = 94500000 915000000 927000000
 net.ipv4.tcp_max_orphans = 3276800
 net.ipv4.tcp_max_syn_backlog = 65536
EOF
fi

#使网络优化生效
sysctl -p
echo "sysctl is executed!"
 
# 禁用selinux
if ! grep "SELINUX=disabled" /etc/selinux/config &>/dev/null; then
sed -i '/SELINUX/{s/enforcing/disabled/}' /etc/selinux/config
sed -i '/SELINUX/{s/permissive/disabled/}' /etc/selinux/config
fi
 
# 关闭防火墙
if egrep "7.[0-9]" /etc/redhat-release &>/dev/null; then
   systemctl stop firewalld
   systemctl disable firewalld
elif egrep "6.[0-9]" /etc/redhat-release &>/dev/null; then
    service iptables stop
    chkconfig iptables off
fi
 

# 修改交换分区策略，内存使用90后启用交换分区
if ! grep "vm.swappiness=10" /etc/sysctl.conf &>/dev/null; then
cat >> /etc/sysctl.conf << EOF
  vm.swappiness=10 
EOF
fi
 
# 设置最大打开文件数
if ! grep "* soft nofile 65535" /etc/security/limits.conf &>/dev/null; then
cat >> /etc/security/limits.conf << EOF
  *   soft noproc   65535  
  *   hard noproc   65535  
  *   soft nofile   65535  
  *   hard nofile   65535 
EOF
fi
 
# 修改环境变量
if ! grep "ulimit -d unlimited" /etc/profile &>/dev/null; then
cat >> /etc/profile << EOF
  ulimit -u 65535  
  ulimit -n 65535
  ulimit -d unlimited  
  ulimit -m unlimited  
  ulimit -s unlimited  
  ulimit -t unlimited  
  ulimit -v unlimited
EOF
fi

#使环境变量生效
source /etc/profile
echo "profile is executed!"

# 创建algo用户
if ! id "algo" &>/dev/null; then
 useradd algo
 echo algo | passwd --stdin TFZQalgo &>/dev/null
 echo "algo User create successful."
else
 echo "algo User already exists!"
fi

# 切换algo用户并新建softwares文件夹
if [ ! -d "/home/algo/softwares/" ];then
 su - algo -c "mkdir softwares"
 echo "file softwares is created!"
else
 echo "file softwares already exists!"
fi


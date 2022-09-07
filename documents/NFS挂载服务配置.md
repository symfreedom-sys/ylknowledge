# 一．NFS挂载服务配置

我们系统部署需要用nfs，主要是快照落盘数据，最后是在页面展示k线图使用。

涉及的程序有行情程序和总线程序。 其中行情程序，一般我们是放在/home/yulmd （如果是直接接券商的行情，名称可能会不通），总线程序路径/hom/algo/quote。

## **第一步**、服务端配置

**首先是服务端配置，服务端提供文件系统供客户端来挂载使用，一般是行情所在服务器。检查是否安装软件rpcbind、nfs-utils**

```bash
yum info rpcbind
```

```bash
已加载插件：fastestmirror
Loading mirror speeds from cached hostfile
已安装的软件包
名称   ：rpcbind
架构   ：x86_64
版本   ：0.2.0
......          //省略部分信息
```

```bash
yum info nfs-utils
```

```bash
已加载插件：fastestmirror
Loading mirror speeds from cached hostfile
已安装的软件包
名称   ：nfs-utils
架构   ：x86_64
时期   ：1
版本   ：1.3.0
```

##若没有安装，则安装rpcbind、nfs-utils

```bash
yum -y install nfs-utils  
yum -y install rpcbind
```

## **第二**步、配置nfs访问目录

**安装完成之后配置nfs访问目录，配置文件位置/etc/exports，默认是空的，需要添加一行：**

```bash
vim /etc/exports
```

\##在空白处添加一行

```bash
/home/yulmd/quote 10.18.101.31(rw,no_root_squash,async)
```

```bash
这个配置表示开放本地存储目录/home/yulmd/quote 只允许10.18.101.31这个主机有访问权限，rw表示允许读写；no_root_squash表示root用户具有完全的管理权限；no_all_squash表示保留共享文件的UID和GID，此项是默认不写也可以；async表示数据可以先暂时在内存中，不是直接写入磁盘，可以提高性能，另外也可以配置sync表示数据直接同步到磁盘；就配置这些就可以，保存退出。

ip那里可以写成10.18.101.0/24表示允许地址段的所有主机访问
```

## **第三步、**启动相关服务

**配置完这些配置，启动相关服务：**

```bash
systemctl stop nfs.service        #关闭nfs
systemctl stop rpcbind.services   #关闭rpcbind
systemctl start rpcbind.services  #启动rpcbind
systemctl start nfs.service       #启动nfs
systemctl enable rpcbind.service  #设置开机启动rpcbind
systemctl enable nfs.service      #设置开机启动nfs
```

启动之后可以通过status来查看状态，如果下次修改了配置，可以重启服务来使配置生效，也可以直接执行如下命令刷新配置：

```bash
exportfs -a
```

## 第四步、配置客户端

服务端配置完毕，可以在对应的主机上来配置客户端了，需要的环境和服务端一样，要保证安装nfs-utils和rpcbind，一般为总线程序服务器。

## **第五步、查看NFS服务**

**在客户端使用showmount -e查看是否能看到服务端的NFS服务**

```bash
showmount -e 10.18.101.34       #查看NFS共享目录，需要替换ip地址
Export list for 10.18.101.34:  
/home/yulmd/quote 10.18.101.31  #服务器端NFS共享的目录
```

## **第**六步、挂载nfs

**可以查看到NFS服务，则挂载nfs**

```bash
mount 10.18.101.34:/home/yulmd/quote  /home/algo/quote
df -Th
```

```bash
文件系统                         类型  容量 已用 可用 已用%  挂载点
10.18.101.34:/home/yulmd/quote  nfs4 79G 14G  66G  17%  /home/algo/quote
```

恭喜，这样就表示挂载成功。

 

# 二．**NFS固定端口配置**

[NFS](https://so.csdn.net/so/search?q=NFS&spm=1001.2101.3001.7020)启动时会随机启动多个端口并向RPC注册，为了设置安全组以及iptables规则，需要设置NFS固定端口。NFS服务需要开启 mountd,nfs,nlockmgr,portmapper,rquotad这5个服务，其中nfs、portmapper的端口是固定的，另外三个服务的端口是随机分配的，所以需要给mountd,nlockmgr,rquotad设置固定的端口。

## **第一步、**指定固定端口

**修改nfs配置文件，指定固定的端口**

```bash
vim /etc/sysconfig/nfs
##在文件在末尾添加
RQUOTAD_PORT=3001
LOCKD_TCPPORT=3002
LOCKD_UDPPORT=3002
MOUNTD_PORT=3003
STATD_PORT=3004
```

**重启**[**rpc**](https://so.csdn.net/so/search?q=rpc&spm=1001.2101.3001.7020)**、nfs的配置与服务：**

```bash
systemctl restart rpcbind.service
systemctl restart nfs.service
```

## 第二步、修改配置文件

**修改/etc/modprobe.d/lockd.conf配置文件**

```bash
vim /etc/modprobe.d/lockd.conf
##在文件在末尾添加
options lockd nlm_tcpport=3002 
options lockd nlm_udpport=3002
```

## **第三步、**检查端口

**重启相关服务并检查相应端口是否存在**

```bash
systemctl restart nfs-config
systemctl restart nfs-idmap
systemctl restart nfs-lock
systemctl restart nfs-server
ss -tnlp | grep -E "3000|111|2049" #检查端口是否存在
rpcinfo -p                         #查看端口情况
```

```bash
program vers proto  port service
100000  4  tcp  111 portmapper
100000  3  tcp  111 portmapper
100000  2  tcp  111 portmapper
100000  4  udp  111 portmapper
100000  3  udp  111 portmapper
100000  2  udp  111 portmapper
100024  1  udp 31004 status
100024  1  tcp 31004 status
100005  1  udp 31003 mountd
100005  1  tcp 31003 mountd
100005  2  udp 31003 mountd
100005  2  tcp 31003 mountd
100005  3  udp 31003 mountd
100005  3  tcp 31003 mountd
100003  3  tcp  2049 nfs
100003  4  tcp  2049 nfs
100227  3  tcp  2049 nfs_acl
100003  3  udp  2049 nfs
100003  4  udp  2049 nfs
100227  3  udp  2049 nfs_acl
100021  1  udp 31002 nlockmgr
100021  3  udp 31002 nlockmgr
100021  4  udp 31002 nlockmgr
100021  1  tcp 31002 nlockmgr
100021  3  tcp 31002 nlockmgr
100021  4  tcp 31002 nlockmgr
```


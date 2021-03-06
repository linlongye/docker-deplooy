#!/usr/bin/bash
# 获取当前ip地址
ip_add=`ip a show dev ens192|grep -w inet|awk '{print $2}'|awk -F '/' '{print $1}'`
# canal.example的http地址
ce_http="172.16.1.122"
# canal.example的Localhost地址
ce_localhost="null"

echo "当前ip地址为$ip_add"
read -t 30 -p "是否清除原有镜像[y/n]" isReset
echo $isReset
if [ $isReset == "n" ]; then
    docker-compose down
elif [ $isReset == "y" ]; then
    # 使用root账号执行脚本
    echo "清除原有镜像和容器..."
    docker rm -f `docker ps -aq`
    docker rmi -f `docker images -q`
    echo "正在导入png镜像..."
    #导入png镜像，该镜像提供情报板图片生产服务，此服务因为需要在容器中安装中文字体，比较麻烦，所有通过导入现有镜像的方式创建
    # 如果以后该服务有修改需要替换原有服务，只需将新的服务使用docker cp 命令拷贝至容器的/root/dotnet目录下重启服务即可
    docker import - png <./png/png.tar 
    echo "正在创建png容器..."
    docker run -d --name png -p 14000:14000 --privileged --restart  png dotnet /root/dotnet/MyPng.dll 

    echo "正在导入canal..."
    docker import - canal < ./canal/canal.tar
    echo "正在创建canal容器..."
    docker run -d --name canal -p 11111:11111 -p 11112:11112 --restart canal sh -c '/root/canal/bin/stop.sh && /root/canal/bin/startup.sh'
else
    echo "错误输入"
    exit -1if
fi

# rm -rf ./png/png.tar
# 移动map.war到/data/map目录下

if [ ! -d "/data/map" ]; then 
    mkdir /data/map
else 
    rm -rf /data/map/map.tar.gz
fi
cp ./map/map.tar.gz /data/map/map.tar.gz
echo "正在解压map.tar.gz"
tar -zxf /data/map/map.tar.gz -C /data/map/
rm -f /data/map/map.tar.gz 
# 移动monitor-webAPP到/data/webapp目录下

if [ ! -d "/data/webapp" ]; then
    mkdir /data/webapp
else 
    rm -rf /data/webapp/monitor-webAPP.war
fi
echo "拷贝monitor-webAPP.war"
cp ./webapp/monitor-webAPP.war /data/webapp/monitor-webAPP.war
echo "正在使用docker-compose创建容器..."
docker-compose up --build -d

sleep 1m

# 重启
# docker-compose restart

# 替换下面两个文件中的ip地址
# docker exec -i webapp sed -i "s/ip_address/172.16.1.122/g" /usr/local/tomcat/webapps/monitor-webAPP/Web_BS/src/assets/js/common/Ajax.js
# docker exec -i webapp sed -i "s/ip_address/172.16.1.122/g" /usr/local/tomcat/webapps/monitor-webAPP/cfg/proxyConfig
# docker exec -i webapp sed -i "s/ip_address/172.16.1.122/g" /usr/local/tomcat/webapps/monitor-webAPP/Web_BS/map/tunnel/base/init.js
docker exec -i webapp sed -i "s/ip_address/$ip_add/g" /usr/local/tomcat/webapps/monitor-webAPP/Web_BS/src/assets/js/common/Ajax.js
docker exec -i webapp sed -i "s/ip_address/$ip_add/g" /usr/local/tomcat/webapps/monitor-webAPP/cfg/proxyConfig
docker exec -i webapp sed -i "s/ip_address/$ip_add/g" /usr/local/tomcat/webapps/monitor-webAPP/Web_BS/map/tunnel/base/init.js

# sleep 10

if [ -f "./mysql/cdjs_v2.sql" ]; then
    userName="root"
    password="root"
    dbName="cdjs_v2"
    sqlPath="./mysql/cdjs_v2.sql" #定义sql文件目录
    # containerSqlPath="/data/cdjs_v2.sql" #定义mysql容器中的sql文件存放路径
    createDbSql="create database cdjs_v2" #定义数据库创建语句
    # docker cp $sqlPath mysql:$containerSqlPath #将宿主机上的cdjs_v2.sql文件复制到mysql容器中
    # 拷贝配置文件
    cp ./mysql/mysqld.cnf /data/mysql/conf/mysqld.cnf

    #创建cdjs_v2数据库
    # mysql -u$userName -p$password -e $createDbSql
    docker exec -i mysql mysql -u$userName -p$password -e "CREATE DATABASE cdjs_v2;"

    docker-compose restart mysql

    sleep 20

    #向cjds_v2数据库中导入sql文件
    # mysql -u$userName -p$password $dbName < $containerSqlPath 
    echo "正在导入数据库文件..."
    docker exec -i mysql mysql -u$userName -p$password --default-character-set=utf8 cdjs_v2 < ./mysql/cdjs_v2.sql
    
fi

docker-compose restart webapp

# docker run -ti --name canal -p 11111:11111 -p 11112:11112 openjdk:8-jdk-alpine


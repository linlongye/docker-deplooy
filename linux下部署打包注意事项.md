# docker-compose的yml文件内容：
## docker-compose.yml
```yml
version: "3"
services:
  # 基础服务之一，不需要任何修改
  mysql: 
    image: mysql:5.6
    container_name: mysql
    privileged: true
    environment:
      MYSQL_ROOT_PASSWORD: root
    # mysql服务的卷引用，将容器中的主要目录映射到宿主机中，保证数据的持久化
    volumes:
      - /data/mysql/data:/var/lib/mysql
      - /data/mysql/conf:/etc/mysql/conf.d
      - /data/mysql/logs:/logs
    ports:
      - 3306:3306
  # 基础服务之一，不需要任何修改
  activemq:
    image: webcenter/activemq:latest
    container_name: activemq
    ports:
      - 8161:8161
      - 61616:61616
  # 服务打包时需将mysql地址改为"jdbc:mysql://mysql:3306/yanshi?characterEncoding=utf8&useSSL=true"
  # activemq地址改为 activemq
  db:
    build: ./db
    image: cdjs:db
    ports:
      - 8081:8081
    container_name: db
    depends_on:
      - mysql
      - activemq
  # 服务打包时需将mysql地址改为"jdbc:mysql://mysql:3306/yanshi?characterEncoding=utf8&useSSL=true"
  control:
    build: ./control
    image: cdjs:control
    ports: 
      - 8082:8082
    container_name: control
    depends_on:
      - db
  # 基础服务 需要把war包换成现在项目的地图
  map:
    image: tomcat:8.5.15
    container_name: map
    privileged: true
    volumes:
      - /data/map/map:/usr/local/tomcat/webapps/map
    ports:
      - 21001:8080
  # 注意更改monitor-webAPP中的相应地址为服务地址
  webapp:
    image: tomcat:8.5.15
    container_name: webapp
    privileged: true
    volumes:
      - /data/webapp/monitor-webAPP.war:/usr/local/tomcat/webapps/monitor-webAPP.war
    ports:
      - 80:8080
    depends_on:
      - db
      - map
      - control
      # 需要使用shell脚本启动的png容器
    external_links:
      - png
# networks: 
#   cdjs:
```

## install.sh
```sh
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
    docker run -d --name png -p 14000:14000 --privileged  png dotnet /root/dotnet/MyPng.dll 
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
# docker exec -i webapp sed -i "s/ip_address/172.16.1.121/g" /usr/local/tomcat/webapps/monitor-webAPP/Web_BS/src/assets/js/common/Ajax.js
# docker exec -i webapp sed -i "s/ip_address/172.16.1.121/g" /usr/local/tomcat/webapps/monitor-webAPP/cfg/proxyConfig
# docker exec -i webapp sed -i "s/ip_address/172.16.1.121/g" /usr/local/tomcat/webapps/monitor-webAPP/Web_BS/map/tunnel/base/init.js
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


```
# **db打包注意事项：**
## 修改application.properties配置文件
* ## 数据库连接字符串
    ```properties
        spring.datasource.url=jdbc:mysql://mysql:3306/cdjs_v2?characterEncoding=utf8&useSSL=true
    ```
    ### spring.datasource.url=jdbc:mysql://<label style="color:red">mysql</label>:3306/cdjs_v2?characterEncoding=utf8&useSSL=true
    #### 红色字体<label style="color:red">mysql</label>需要保持和上面的docker-compose.yml中mysql中的*container_name*保持一致
* ## activemq地址
    ```properties
        mq.session.host=activemq
    ```
    ### mq.session.host=<label style="color:red">activemq</label>中的红色部分需要和docker-compose.yml中activemq中的*container_name*保持一致
* ## 控制服务URL配置
    ```properties
        btControl.host=http://control:
    ```
    ### btControl.host=http://<label style="color:red">control</label>:中的红色部分需要和docker-compose.yml中control中的*container_name*保持一致
* ## 将*com.jdjinsui.ms.dbservice.cfg.DataHourOrDayAddCfg*类中的<label style="color:green">**DayData**</label>和<label style="color:green">**batchTimeTrigger**</label>两个方法的方法体注释
* ## 最后使用<label style="color:green">**mvn clean package -DskipTests**打包生产jar包</label>

***
# **control打包注意事项：**
## 修改application.properties配置文件
* ## activemq地址
    ```proterties
    ProducerHost=activemq
    ```
    ### ProducerHost=<label style="color:red">activemq</label>中的红色部分需要和docker-compose.yml中activemq中的*container_name*保持一致
* ## URL地址配置
    ```proterties
    urlCfg.operLog = http://db:8081/operationLog/insert
    urlCfg.comLog = http://db:8081/commandLog/insert
    urlCfg.cmsCfg = http://db:8081/cmsCfg/search
    urlCfg.stateHistory = http://db:8081/equipmentStateHistoryData/add
    urlCfg.allControl = http://db:8081/controlTransformation/all
    urlCfg.tvCfg=http://db:8081/ThirdPartySystemCfg/selectTvCfg
    urlCfg.equData=http://db:8081/equipments/selectById
    urlCfg.LEDCfg=http://db:8081/ledCtrl/getLedCfg
    urlCfg.cmsDataProcessing=http://db:8081/cmsThirdPartyOpt/cmsDataProcessing
    urlCfg.updateByElement=http://db:8081/cmsPics/updateByElement
    urlCfg.selectRole=http://db:8081/user/roleAuth
    urlCfg.queryScreens=http://db:8081/screenCtrl/queryScreens
    urlCfg.elements=http://db:8081/element/search
    ```
    ### 类似urlCfg.operLog = http://<label style="color:red">db</label>:8081/operationLog/insert中的红色部分需要和docker-compose.yml中db中的*container_name*保持一致
    ```
    ##是否需要转发 1：需要 0：不需要
    urlCfg.isForward=1
    ```
    ### 是否需要转发，中心需要转发配置1，其他不需要转发配置0
* ## java代码中修改activemq地址
    ### 修改<label style="color:green">*com.jdjinsui.controlservice.tool.ActiveMQHelper.java:428*</label>
    ```java
    sessionCfg.setUser("dbservice");
    ```
* ## 打开控制状态入库代码
    ### 取消注释<label style="color:green">*com.jdjinsui.controlservice.controller.EquipmentController.java:361-363*</label>
    ```java
    if (result.isSuccess() && allHistoryParam.getParam() != null && allHistoryParam.getParam().size() > 0) {
        changeStateHistory(allHistoryParam);
    }
    ```
* ## 最后使用<label style="color:green">**mvn clean package -DskipTests**打包生产jar包</label>
    ***

# **monitor-webAPP打包注意事项：**
* ## 修改proxyConfig文件中的db和chotrol地址
    ### 将proxyConfig文件中红的所有IP地址(默认应该是127.0.0.1)修改为部署服务器上的宿主机地址(e.g 172.16.1.120)，所有有端口保持不变。<label style="color:red">文件保存格式应该ANSI，不要修改为utf8。</lable>
* ## 修改isDown文件
    ```javascript
    [
        {"name":"cmsCtrl/add","tranUrl":"http://db:8081/trans/transAddCms","note":"情报板缓存记录"},
        {"name":"alarmInstantLinksDatas/disposeAlarmInstantLink","tranUrl":"http://db:8081/trans/transAlarm","note":"解除警报"}
    ]
    ```
* ## web.xml文件的修改
    ### 路段配置
    ```xml
    <!--是否需要往上层传送mq  不需要就是0需要的话就是 路径 http://ip:20001/ -->
    <context-param>
        <param-name>mqIsUp</param-name>
        <param-value>0</param-value>
    </context-param>

    <!--是否需要往下传  0 不需要 1需要 1代表上端-->
    <context-param>
        <param-name>down</param-name>
        <param-value>1</param-value>
    </context-param>
    ```
    ### 中心配置
    ```xml
    <!--是否需要往上层传送mq  不需要就是0需要的话就是 路径 http://ip:20001/ -->
    <context-param>
        <param-name>mqIsUp</param-name>
        <param-value>http://172.16.1.122</param-value>
    </context-param>

    <!--是否需要往下传  0 不需要 1需要 1代表上端-->
    <context-param>
        <param-name>down</param-name>
        <param-value>1</param-value>
    </context-param>
    ```
    xml文件中其他的类似以下的配置中都需要把ip地址改成docker-compose中的db的container_name
    ```xml
    <context-param>
        <param-name>btInstankDataAPI</param-name>
        <param-value>http://db:8081/btInstankData/selectBlurBtData</param-value>
    </context-param>
    ```
* ## 修改<label style="color:green">*com/monitor/mq/CMsgMQ.java:99*</label>
    ```java
        sessionCfg.setHost("activemq");
        sessionCfg.setPort(61616);
        sessionCfg.setUser("monitor-webAPP");
        sessionCfg.setPwd("manager");
    ```
* ## Web_BS的Ajax.js的修改
    ```javascript
    const servers = {
        // 代理请求的地址
        proxyUrl:"http://ip_address/monitor-webAPP/Proxy",

        // 应急聊天
        chatUrl:"http://ip_address/monitor-webAPP/chat2",

        // 情报板gif请求地址
        cmsGifUrl: "http://ip_address/monitor-webAPP/PngOrGifServlet",

        //导出excel
        excel: 'http://ip_address/monitor-webAPP/ReportServlet',

        //登录
        login: "http://ip_address/monitor-webAPP/Login",

        //webSocket
        webSocket: "ws://ip_address/monitor-webAPP/testSocket",
        
        // cctv
        // cctv:"http://172.16.1.140:8090/TvHandler.ashx?cctvId=",

        //cms png
        cmsPng: 'http://ip_address:14000/Png?',

        // 视频请求地址
        cctv: 'http://ip_address:14000/TvHandler.ashx',

        // 情报板三方图片地址
        cmsImgUrl: "http://ip_address:8081",
    }
    ```
 
    ### 注意<label style="color:red">cmsPng: 'http://ip_address:14000/Png?'</label>在linux下的配置地址很windows下的不同
    linux
    ```javascript
    cmsPng: 'http://ip_address:14000/Png?',
    ```

    windows
    ```javascript
    cmsPng: 'http://ip_address:14000/PngPage.aspx?',
    ```
* ## 修改<label style="color:green">map/tunnel/base/init.js</label>
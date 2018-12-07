# 使用说明
##  **1.确保所有安装包中的ip地址已更换为服务名**
* db-->db
* png-->png
* map-->map
* mysql-->mysql
* activemq-->activemq
* control-->control
* webapp-->webapp
## **2.安装所有镜像并启动容器**
* 首先确保系统为centos7，并且已经成功安装了docker，docker-compose两个工具
* 切换到root用户
    ```shell
    su root
    ```
* 确保 install.sh 文件有可执行权限，如果没有先赋予权限
    ```shell
    chmod +x install.sh
    ```
* 替换windows下的\r\n为linux下的\n
    ```shel
    sed -i 's/\r$//' install.sh
    ```
* 执行 install.sh 文件
    ```shell
    ./install.sh
    ```
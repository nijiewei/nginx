#!/bin/sh
<<!
 **********************************************************
 * Author        : zhangzm
 * Email         : zhangzm@gzcltech.com
 * Last modified : 
 * Filename      : flash_sdk
 * Description   : 
 * *******************************************************
!


#update config for chainmanage
if [ ! -d '/opt/tomcat_80' ]
then

    echo "no has /opt/tomcat_80"
else
    #has chainmanage
    #update orguser.xml 
    orguser_path='/opt/tomcat_80/webapps/ChainManage/WEB-INF/classes'
    new_can=`date +'%Y%m%d%H%M%S'`
    old_can=`cat $orguser_path/orguser.xml |grep 'user' |cut -d '<' -f2 |cut -d '>' -f2`
    #echo $old_can
    sed -i 's/'"$old_can"'/'"$new_can"'/g' $orguser_path/orguser.xml
    #restart tomcat_80
    # tomcat80_pid=`ps -ef |grep '/opt/tomcat_80'|grep -v grep |awk '{print $2}'`
    # if [ -n "$tomcat80_pid" ]
    # then
    #     echo "tomcat restarting"
    #     kill -9 $tomcat80_pid
    #     sleep 2
    #     /opt/tomcat_80/bin/startup.sh
    #     sleep 3
    #     tomcat80_pid1=`ps -ef |grep '/opt/tomcat_80'|grep -v grep |awk '{print $2}'`
    #     if [ -n "$tomcat80_pid1" ]
    #     then
    #         echo "tomcat_80 restart ready"
    #     fi
    # else
    #     /opt/tomcat_80/bin/startup.sh
    # fi

fi

#start CLRService
sh /opt/CLRService/run.sh stop
config_path='/opt/CLRService/resource'
config_new_can=`date +'%Y%m%d%H%M%S'`
config_old_can=`cat $config_path/config.json  |cut -d ',' -f3 |cut -d ':' -f2 | sed 's/\"//g'`
org_number=`cat $config_path/config.json |cut -d ',' -f4|cut -d '.' -f2`
sed -i 's/'"$config_old_can"'/'"$org_number$config_new_can"'/g' $config_path/config.json


#flash fabric_sdk

code_p=`ps -ef |grep code*/app |awk '{print $9}'`
#start supervisor
supervisorctl shutdown

#1check node
has_node=`ps -ef |grep node |grep app |grep -v grep|awk '{print $2}'`
has_ipfs=`ps -ef |grep ipfs|grep -v grep|awk '{print $2}'`
supervisorid=`ps -ef |grep supervisord |grep -v grep |awk '{print $2}'`
if [ -n "$supervisorid" ]
then
{
   kill -9 $supervisorid
   sleep 1
   kill -9 $has_node
   sleep 1
   kill -9 $has_ipfs
}
else
   echo "supervisord stoped"
fi
#clear fabric-kv
#code path

code_path=${code_p%%'/app'*}
rm -rf /opt/gopath/src/github.com/hyperledger/code/fabric-client-kv*
rm -rf /tmp/fabric-client-kv*

#start supervisor
#get supervisord.conf path
sup_path=`find /etc/supervisor* -name supervisor*.conf`
supervisord -c $sup_path

#reboot all tomcat
all_tomcat=`ps -ef |grep java |grep -v grep |grep -v CLRService |awk '{print $2}'`
#echo $all_tomcat

for i in $all_tomcat
do
    tomcat_path=`ps -ef |grep $i |grep -v grep |awk '{print $17}'  |cut -d '=' -f2`
    kill -9 $i   
    echo $tomcat_path  'starting'
    $tomcat_path/bin/startup.sh
done

#start CLRService
cd /opt/CLRService
./run.sh start




















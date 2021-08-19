#!/bin/bash
export HOME=/root

RED='tput setaf 1'
GREEN='tput setaf 2'
BLACK='tput sgr0'

name=""
InstanceId=""
InstanceStatus=""
ts=$(date "+%Y-%b-%d %H:%M:%S")

banner(){
    echo ""
    echo ""
    echo "     ___   ____    __    ____   _______.     ______  __       __  "
    echo "    /   \  \   \  /  \  /   /  /       |    /      ||  |     |  | "
    echo "   /  ^  \  \   \/    \/   /  |   (----    |  ,----'|  |     |  | "
    echo "  /  /_\  \  \            /    \   \       |  |     |  |     |  | "
    echo " /  _____  \  \    /\    / .----)   |      |   ----.|   ----.|  | "
    echo "/__/     \__\  \__/  \__/  |_______/        \______||_______||__| "
    echo ""
    echo ""
}
set(){
    name=$1
    InstanceId=$(aws ec2 describe-instances --no-cli-pager --filters "Name=tag:Name,Values=$name" --output json | jq .Reservations[].Instances[].InstanceId | sed 's/"//g')
    InstanceStatus=$(aws ec2 describe-instances --no-cli-pager --filters "Name=tag:Name,Values=$name" --output json | jq .Reservations[].Instances[].State.Name | sed 's/"//g' )
}
check(){
    if [ -z $1 ]
    then
        banner
        echo "./aws-tb.sh help"
        exit 0
    fi
}
status(){
    detail=$InstanceStatus
    if [[ $detail == 'running' ]]
    then
        echo -n "Name : $name = ";${GREEN}; echo -n $detail ; ${BLACK}; echo ""
        echo "$ts - Name : $name = Running " >> /var/log/aws.log
    else
        echo -n "Name : $name = ";${RED}; echo -n $detail ; ${BLACK}; echo ""
        echo "$ts - Name : $name = Stopped " >> /var/log/aws.log
    fi
    exit 0
}
stop(){
    c=$(status)
    checkStatus=$(echo $c | grep running | wc -l )
    if [ $checkStatus == 1 ]
    then
        cmd=$(aws ec2 stop-instances --no-cli-pager --instance-ids $InstanceId | jq .StoppingInstances[].CurrentState.Name | sed 's/"//g')
        echo "Stop $name : $InstanceId : State : $cmd "
        echo "$ts - Stop $name : $InstanceId : State : $cmd " >> /var/log/aws.log
    else
        echo -n "Stop $name : $InstanceId : State : "; ${RED}; echo -n "Already Stopped "; ${BLACK}; echo ""
        echo "$ts - Stop $name : $InstanceId : State : Already Stopped " >> /var/log/aws.log
    fi
    
}
start(){
    c=$(status)
    checkStatus=$(echo $c | grep running | wc -l )
    if [ $checkStatus == 1 ]
    then
        echo -n "Start $name : $InstanceId : State : "; ${GREEN}; echo -n "Already Start "; ${BLACK}; echo ""
        echo "$ts - Start $name : $InstanceId : State : Already Start " >> /var/log/aws.log
    else
        cmd=$(aws ec2 start-instances --no-cli-pager --instance-ids $InstanceId | jq .StartingInstances[].CurrentState.Name | sed 's/"//g')
        echo "Start $name : $InstanceId : State : $cmd "
        echo "$ts - Start $name : $InstanceId : State : $cmd " >> /var/log/aws.log
    fi
    
}

case $1 in
    status)
        check "$2"
        set "$2"
        status 
    ;;
    stop)
        check "$2"
        set "$2"
        stop 
    ;;
    start)
        check "$2"
        set "$2"
        start 
    ;;
    config)
        echo "---Config---"
        cat ~/.aws/config
        echo "---Credencials---"
        cat ~/.aws/credentials
    ;;
    *)
        banner
        echo "Options:"
        echo "        config        : Get Access key id, Secret key and Region from configuration <aws configure>."
        echo "        start <Name>  : Start instance."
        echo "        stop <Name>   : Stop instance."
        echo "        status <Name> : Get instance status (running/Stopped)."
        echo ""
    ;;
esac
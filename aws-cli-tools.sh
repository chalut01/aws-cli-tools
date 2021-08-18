#!/bin/bash

RED='tput setaf 1'
GREEN='tput setaf 2'
BLACK='tput sgr0'

name=""
InstanceId=""
InstanceStatus=""

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
    else
        echo -n "Name : $name = ";${RED}; echo -n $detail ; ${BLACK}; echo ""
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
        #echo "stop"
    else
        echo -n "Name $name : $InstanceId : State : "; ${RED}; echo -n "Already Stopped "; ${BLACK}; echo ""
    fi
    
}
start(){
    c=$(status)
    checkStatus=$(echo $c | grep running | wc -l )
    if [ $checkStatus == 1 ]
    then
        echo -n "Name $name : $InstanceId : State : "; ${GREEN}; echo -n "Already Start "; ${BLACK}; echo ""
    else
        cmd=$(aws ec2 start-instances --no-cli-pager --instance-ids $InstanceId | jq .StartingInstances[].CurrentState.Name | sed 's/"//g')
        echo "Name $name : $InstanceId : State : $cmd "
    fi
    
}

case $1 in
    status)
        check "$2"
        set "$2"
        status "$2"
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
        echo "start <name>"
        echo "stop <name>"
        echo "status <name>"
    ;;
esac
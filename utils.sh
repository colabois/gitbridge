#!/usr/bin/env bash

#Setting up color codes
Black='\033[0;30m'
Red='\033[0;31m'
Green='\033[0;32m'
Orange='\033[0;33m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Cyan='\033[0;36m'
Light_Gray='\033[0;37m'
Dark_Gray='\033[1;30m'
Light_Red='\033[1;31m'
Light_Green='\033[1;32m'
Yellow='\033[1;33m'
Light_Blue='\033[1;34m'
Light_Purple='\033[1;35m'
Light_Cyan='\033[1;36m'
White='\033[1;37m'
NC='\033[0m'


edebug () {
    echo -e " ${Blue}*${NC} ${@:1}${NC}"
}


einfo () {
    echo -e " ${Green}*${NC} ${@:1}${NC}"
}


ewarn () {
    echo -e " ${Yellow}*${NC} ${@:1}${NC}"
}


eerror () {
    echo -e " ${Red}*${Light_Red} ${@:1}${NC}"
}


die () {
    echo
    edebug die called, ending.
    exit 1
}


end () {
    exit 0
}

contains () {
    INPUT=$1
    shift
    while true
        do
        if [ "$1" == "$INPUT" ]
            then
            echo true
            break
        fi
        if [ -z "$1" ]
            then
            echo false
            break
        fi
        shift
    done
}

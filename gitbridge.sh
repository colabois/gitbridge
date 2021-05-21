#!/usr/bin/env bash

source utils.sh


SCRIPT_NAME=$0
REAL_ARGS=$@


show_general_help () {
    echo -e "USAGE : ${Light_Green}${SCRIPT_NAME}${NC} ${Yellow}[gloabl options]${NC} ${Green}<action>${NC} ${Light_Red}...${NC} "
    echo -e 
    echo -e "${Green}ACTIONS :${NC}"
    echo -e " install                                   Install GitBridge on the system."
    echo -e " list                                      List keys for the current user."
    echo -e " add                                       Add a new key for the current user."
    echo -e " remove                                    Remove an existing key for the current user."
    echo -e
    echo -e "${Yellow}GLOBAL OPTIONS :${NC}"
    echo -e " -h        --help                          Show this help."
    echo -e "                                           Shows the ${Green}action specific help${NC} if an action is specified."
#    echo -e " -u        --userland,--no-root            Allow the script to run in userland."
    echo -e " -f        --force                         Run even if something fails."
}

show_install_help() {
    echo -e
}

getopt --test
if [ $? != 4 ]; then
    eerror "Your installation doesn't support enhanced getopt."
    die
fi


echo -e ${Light_Blue}  -- GitBridge Managing tool -- ${NC}
echo

SHORT="huf"
LONG="help,userland,no-root,force"

OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ]
    then eerror Failed to parse options
    die
fi


eval set -- "$OPTS"

#Setting default values

ACTIONS="install list add remove"

#GLOBAL VARS

MODE="global"
NO_ROOT=false
SHOW_HELP=false
FORCE=false
ACTION=""
#Extracting arguments
while true
    do
    case "$ACTION" in
        "" )
            case "$1" in
                -h | --help )
                    SHOW_HELP=true
                    shift
                    ;;
                -u | --userland | --no-root )
                    NO_ROOT=true
                    shift
                    ;;
                -f | --force )
                    FORCE=true
                    shift
                    ;;
                -- )
                    shift
                    ;;
                *)
                    if [ -z ${ACTION} ]
                        then ACTION=$1
                        if ! $(contains $ACTION $ACTIONS)
                            then
                            eerror $ACTION is not a valid action.
                            eerror See $SCRIPT_NAME --help for more info.
                            die
                        fi
                    fi
                    shift
                    ;;
            esac
            ;;

        install )
            case in
                "test" )
            shift
            ;;
        
    esac
    if [ -z "$1" ]
        then
        break
    fi
done


if $SHOW_HELP
    then
    show_general_help
    end
fi

if [ -z ${ACTION} ]
    then eerror Please specify an action.
    ewarn Run ${SCRIPT_NAME} --help for more info.
    die
fi

if [ -z ${TARGET} ]
    then eerror Please specify a target.
    ewarn Run ${SCRIPT_NAME} --help for more info.
    die
fi
if ! ${NO_ROOT}
    then
    if [ "$EUID" -ne 0 ]
        then eerror This script should be ran as root.
        ewarn If you want to run the script anyway use the --no-root argument.
        ewarn Warning : Userland chroot generation has not been tested yet.
        die
    fi
fi
if ${NO_ROOT}
    then ewarn Warning : NO_ROOT is experimental.
fi
if ${FORCE}
    then
    die () {
        echo
        eerror die called, but --force option is set.
    }
fi

if [ "${ACTION}" == "shell" ]
    then
    cd ${TARGET} || die
    TARGET=$(pwd)
    export ROOT=${TARGET}
    export PORTAGE_CONFIGROOT=${TARGET}
    export PORTDIR=${TARGET}/usr/portage
    einfo You are entering a new shell.
    einfo When you have finished please run exit to end the program.
    cd ${TARGET}
    bash
    einfo You have left the shell.
fi

#!/usr/bin/env bash

source utils.sh


SCRIPT_NAME=$0
REAL_ARGS=$@


show_general_help () {
    echo -e "USAGE: ${Light_Green}${SCRIPT_NAME}${NC} ${Green}<action>${NC} ${Yellow}[options]${NC} ${Light_Red}...${NC} "
    echo -e
    echo -e "${Green}ACTIONS:${NC}"
    echo -e " list                                      List keys for the current user."
    echo -e " add                                       Add a new key for the current user."
    echo -e " remove                                    Remove an existing key for the current user."
    echo -e " install                                   Install GitBridge on the system."
    echo -e " register                                  Registers a public key for the current user."
    echo -e
    echo -e "${Yellow}OPTIONS:${NC}"
    echo -e " -h        --help                          Show this help."
    echo -e "                                           Shows the ${Green}action specific help${NC} if an action is specified."
    echo -e " -n        --userland,--no-root            Allow the script to run in userland. ${Light_Red}Untested!${NC}"
    echo -e " -f        --force                         Run even if something fails."
    echo -e " --target_home </path/to/target>           Path to the gitbridge installation (/srv/gitbridge by default)"
    echo -e " --target_user <username>                  local account that will be used for gitbridge (git by default)"
}

show_install_help() {
    echo -e "USAGE: ${Light_Green}${SCRIPT_NAME}${NC} ${Green}install${NC} ${Yellow}[options]${NC}"
    echo -e
    echo -e "DESCRIPTION:"
    echo -e "Creates the git user and installs gitbridge on the new user."
    echo -e
    echo -e "${Yellow}OPTIONS:${NC}"
    echo -e " -h        --help                          Show this help."
    echo -e "                                           Shows the ${Green}action specific help${NC} if an action is specified."
    echo -e " -n        --userland,--no-root            Allow the script to run in userland. ${Light_Red}Untested!${NC}"
    echo -e " -f        --force                         Run even if something fails."
    echo -e " --target_home </path/to/target>           Path to the gitbridge installation (/srv/gitbridge by default)"
    echo -e " --target_user <username>                  local account that will be used for gitbridge (git by default)"
}

show_register_help() {
    echo -e "USAGE: ${Light_Green}${SCRIPT_NAME}${NC} ${Green}register${NC} ${Yellow}[options]${NC} ${Light_Cyan}[ssh publickey]${NC}"
    echo -e
    echo -e "DESCRIPTION:"
    echo -e "Register a new public key for the current user."
    echo -e
    echo -e "${Yellow}OPTIONS:${NC}"
    echo -e " -h        --help                          Show this help."
    echo -e "                                           Shows the ${Green}action specific help${NC} if an action is specified."
    echo -e " -n        --userland,--no-root            Allow the script to run in userland. ${Light_Red}Untested!${NC}"
    echo -e " -f        --force                         Run even if something fails."
    echo -e " --target_home </path/to/target>           Path to the gitbridge installation (/srv/gitbridge by default)"
    echo -e " --target_user <username>                  local account that will be used for gitbridge (git by default)"
}
getopt --test
if [ $? != 4 ]; then
    eerror "Your installation doesn't support enhanced getopt."
    die
fi


echo -e ${Light_Blue}  -- GitBridge Managing tool -- ${NC}
echo

SHORT="hnu:f"
LONG="help,user:,userland,no-root,force,target-user:,target-home:"

OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
if [ $? != 0 ]
    then eerror Failed to parse options
    die
fi


eval set -- "$OPTS"

#Setting default values

ACTIONS="list add remove install register"

#GLOBAL VARS

NO_ROOT=false
SHOW_HELP=false
FORCE=false
ACTION=""
#Extracting arguments
edebug $@
while true
    do
        case "$1" in
            -h | --help )
                SHOW_HELP=true
                shift
                ;;
            -n | --userland | --no-root )
                NO_ROOT=true
                shift
                ;;
            -f | --force )
                FORCE=true
                shift
                ;;
            --target-home )
                TARGET_HOME=$2
                shift 2
                ;;
            --target-user )
                TARGET_USER=$2
                shift 2
                ;;
            -u | --user )
                CURRENT_USER=$2
                shift 2
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
                    shift
                    break
                fi
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
    if [ "${ACTION}" == "install" ]
        then
        show_install_help
    else
        show_general_help
    fi
    end
fi

if [ -z ${ACTION} ]
    then eerror Please specify an action.
    ewarn Run ${SCRIPT_NAME} --help for more info.
    die
fi

if [ -e ${TARGET_USER} ]
    then
    edebug Using default target user
    TARGET_USER=git
fi

if [ -z ${TARGET_HOME} ]
    then
    edebug Using default target
    TARGET_HOME=/srv/git
fi

if ! ${NO_ROOT}
    then
    if [ "$EUID" -ne 0 ]
        then
        eerror This script should run as root.
        ewarn If you want to run the script anyway use the --no-root argument.
        ewarn Warning : Userland GitBridge installation has not been tested yet.
        die
    fi
else
    ewarn Warning : NO_ROOT is experimental.
fi

if [ -z ${CURRENT_USER} ]
    then
    CURRENT_USER=$SUDO_USER
    if [ -z ${CURRENT_USER} ]
        then
        CURRENT_USER=$(who am i | awk '{print $1}' | tail -n 1)
    fi
    ewarn No user specified, assuming user is $CURRENT_USER
fi
if ${FORCE}
    then
    die () {
        echo
        eerror die called, but --force option is set.
    }
fi


if [ "${ACTION}" == "install" ]
    then
    #User creation
    id $TARGET_USER > /dev/null 2>&1 
    if [ $? -ne 0 ]
        then
        einfo Creating user $TARGET_USER with home directory $TARGET_HOME.
        useradd -m -d "$TARGET_HOME" "$TARGET_USER"
    else
        TARGET_HOME=$( getent passwd "$TARGET_USER" | cut -d: -f6 )
        ewarn User $TARGET_USER already exists. Home directory is $TARGET_HOME.
    fi
    
    WORKDIR="$TARGET_HOME/.gitbridge/"
    
    #Setting up home directory structure.
    einfo Setting up $TARGET_HOME directory structure.
    mkdir -p "$WORKDIR/users/"
    cp bridge.py "$WORKDIR"/bridge
fi

if [ "${ACTION}" == "register" ]
    then
    id $TARGET_USER > /dev/null 2>&1
    if [ $? -ne 0 ]
        then
        eerror User $TARGET_USER does not exist. Exiting.
        die
    fi
    TARGET_HOME=$( getent passwd "$TARGET_USER" | cut -d: -f6 )
    WORKDIR="$TARGET_HOME/.gitbridge/"
    
    mkdir -p "$WORKDIR/users/$CURRENT_USER/"
fi

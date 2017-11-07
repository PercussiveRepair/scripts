#!/bin/bash
# Script to remove IAM Users from one or more accounts based on a grep search for the name


function usage()
{
cat <<EOF
iam_remove_user.sh [hu]

    Searches for and removes IAM creds for the given users in the given accounts
    This script uses a grep the initial search of the username. Be very careful
    about vague usernames

    options:
      -h this help
      -u username (or part)
      -p AWS credentials profile name to use ( defaults to ALL)
      -d if set, disables user (removes console login and deactivates keys)
      -D if set, deletes user completely
EOF
}

# read any command line options
while getopts hu:p:dD opt; do
    case "${opt}" in
        h) usage; exit 0;;
        u) IAMUSER=${OPTARG};;
        p) PROFILE=${OPTARG};;
        d) DISABLEIAMIAMUSER=y;;
        D) DELETEIAMIAMUSER=y;;
    esac
done

# shift away any command line options that
# have already been read
shift $((OPTIND-1))

# check for username
if [ ${#IAMUSER} -eq 0 ]; then
  echo "-u username required. Exiting."
  exit 1
fi

# set profile to all if empty
if [ ${#PROFILE} -eq 0 ]; then
  echo "Using all profiles"
  PROFILE=$(cat ~/.aws/credentials | grep "\[" | grep -v -e "default" | sort -t[ -k2 | tr '\n' ' ' | tr -d '[]')
fi

#colour output
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'
#delete confirmation
if [[ $DELETEIAMIAMUSER = "y" ]]; then
  read -r -p "Caution. This will delete all users with '$IAMUSER' in their username. Continue? [Y/n] " INPUT
  if [[ $INPUT =~ ^[Yy]$ ]]; then
    CONFIRMDELETEIAMIAMUSER="y"
    echo "Don't say I didn't warn you"
  else
    CONFIRMDELETEIAMIAMUSER=""
    echo "Ok I'll just search then"
  fi
fi

#starting the search
echo -n "Running, please wait"
for p in ${PROFILE}; do
  IAMIAMUSER=$(aws --profile $p iam list-users | jq -r '.Users[] | .UserName' | grep -i ${IAMUSER})
  if [[ ! -z $IAMIAMUSER ]]; then
    echo -e "\\n${RED}${p}${NC}"
    echo "$IAMIAMUSER found"
    #find users managed policies, if none set deleted to true
    MANAGEDPOLICYARNS=$(aws --profile $p iam list-attached-user-policies --user-name ${IAMIAMUSER} | jq -r '.AttachedPolicies[].PolicyArn' 2>/dev/null)
    [[ -z "$MANAGEDPOLICYARNS" ]] && MANAGEDPOLICYARNSDELETED="y" && echo "No Managed Policies" || echo -e "${CYAN}Managed Policies${NC}:\n$MANAGEDPOLICYARNS"
    #find user inline policies, if none set deleted to true
    INLINEPOLICYARNS=$(aws --profile $p iam list-user-policies --user-name ${IAMIAMUSER} | jq -r '.PolicyNames[]' 2>/dev/null)
    [[ -z "$INLINEPOLICYARNS" ]] && INLINEPOLICYARNSDELETED="y" && echo "No Inline Policies" || echo -e "${CYAN}Inline Policies${NC}:\n$INLINEPOLICYARNS"
    #find user groups, if none set deleted to true
    IAMUSERGROUPS=$(aws --profile $p iam list-groups-for-user --user-name ${IAMIAMUSER} | jq -r '.Groups[].GroupName' 2>/dev/null)
    [[ -z "$IAMUSERGROUPS" ]] && IAMUSERGROUPSDELETED="y" && echo "No User Groups" || echo -e "${CYAN}Groups${NC}:\n$IAMUSERGROUPS"
    #find users access/secret keypairs and show status, if none set deleted to true
    ACCESSKEYSSTATUS=$(aws --profile $p iam list-access-keys --user-name ${IAMIAMUSER} | jq -r '.AccessKeyMetadata[] | [.AccessKeyId,.Status]  | @tsv ' 2>/dev/null)
    ACCESSKEYS=$(aws --profile $p iam list-access-keys --user-name ${IAMIAMUSER} | jq -r '.AccessKeyMetadata[] | .AccessKeyId' 2>/dev/null)
    [[ -z "$ACCESSKEYS" ]] && ACCESSKEYSDELETED="y" && echo "No Access Keys" || echo -e "${CYAN}Access Keys${NC}:\n$ACCESSKEYSSTATUS"
    #find login profile, if none set deleted to true
    LOGINPROFILE=$(aws --profile $p iam get-login-profile --user-name ${IAMIAMUSER} 2>/dev/null)
    [[ -z "$LOGINPROFILE" ]] && LOGINDELETED="y" && echo "No Login Profile" || echo "Login Profile exists"

    #disable rather than deleting user
    if [[ $DISABLEIAMIAMUSER = "y" ]]; then
      echo "Disabling..."
      if [[ ! -z "$LOGINPROFILE" ]]; then
        aws --profile $p iam delete-login-profile --user-name ${IAMIAMUSER} 2>/dev/null
      fi
      if [[ ! -z "$ACCESSKEYS" ]]; then
        for key in $ACCESSKEYS; do
          aws --profile $p iam update-access-key --access-key ${key} --user-name ${IAMIAMUSER} --status Inactive 2>/dev/null
        done
      fi
    fi

    #completely delete user
    if [[ $CONFIRMDELETEIAMIAMUSER = "y" ]]; then
      echo "Deleting..."
      if [[ ! -z "$MANAGEDPOLICYARNS" ]]; then
        for managedpolicy in $MANAGEDPOLICYARNS; do
          aws --profile $p iam detach-user-policy --user-name ${IAMIAMUSER} --policy-arn ${managedpolicy}
        done
        MANAGEDPOLICYARNSDELETED="y"
      fi
      if [[ ! -z "$INLINEPOLICYARNS" ]]; then
        for inlinepolicy in $INLINEPOLICYARNS; do
          aws --profile $p iam delete-user-policy --user-name ${IAMIAMUSER} --policy-name ${inlinepolicy}
        done
        INLINEPOLICYARNSDELETED="y"
      fi
      if [[ ! -z "$IAMUSERGROUPS" ]]; then
        for group in $IAMUSERGROUPS; do
          aws --profile $p iam remove-user-from-group --user-name ${IAMIAMUSER} --group-name ${group}
        done
        IAMUSERGROUPSDELETED="y"
      fi
      if [[ ! -z "$ACCESSKEYS" ]]; then
        for key in $ACCESSKEYS; do
          aws --profile $p iam delete-access-key --access-key ${key} --user-name ${IAMIAMUSER};
        done
        ACCESSKEYSDELETED="y"
      fi
      if [[ ! -z "$LOGINPROFILE" ]]; then
        aws --profile $p iam delete-login-profile --user-name ${IAMIAMUSER}
        LOGINDELETED="y"
      fi
      if [[ LOGINDELETED="y" ]] && [[ ACCESSKEYSDELETED="y" ]] && [[ IAMUSERGROUPSDELETED="y" ]] && [[ INLINEPOLICYARNSDELETED="y" ]] && [[ INLINEPOLICYARNSDELETED="y" ]] && [[ MANAGEDPOLICYARNSDELETED="y" ]]; then
        aws --profile $p iam delete-user --user-name ${IAMIAMUSER}
        echo "${IAMIAMUSER} deleted"
      fi
    fi
  else
    echo -n "."
  fi
done
echo ""

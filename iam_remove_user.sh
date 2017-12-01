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
        u) SEARCHUSER=${OPTARG};;
        p) PROFILE=${OPTARG};;
        d) DISABLEIAMUSER=y;;
        D) DELETEIAMUSER=y;;
    esac
done

# shift away any command line options that
# have already been read
shift $((OPTIND-1))

# check for username
if [ ${#SEARCHUSER} -eq 0 ]; then
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
if [[ $DELETEIAMUSER = "y" ]]; then
  read -r -p "Caution. This will delete all users with '$SEARCHUSER' in their username. Continue? [Y/n] " INPUT
  if [[ $INPUT =~ ^[Yy]$ ]]; then
    CONFIRMDELETEIAMUSER="y"
    echo "Don't say I didn't warn you"
  else
    CONFIRMDELETEIAMUSER=""
    echo "Ok I'll just search then"
  fi
fi

#starting the search
echo -n "Running, please wait"
for p in ${PROFILE}; do
  IAMUSERS=$(aws --profile $p iam list-users | jq -r '.Users[] | .UserName' | grep -i ${SEARCHUSER})
  if [[ ! -z $IAMUSERS ]]; then
    echo -e "\\n${RED}${p}${NC}"
    echo "$IAMUSERS found"
    for IAMUSER in $IAMUSERS; do 
      #find users managed policies, if none set deleted to true
      MANAGEDPOLICYARNS=$(aws --profile $p iam list-attached-user-policies --user-name ${IAMUSER} | jq -r '.AttachedPolicies[].PolicyArn' 2>/dev/null)
      [[ -z "$MANAGEDPOLICYARNS" ]] && MANAGEDPOLICYARNSDELETED="y" && echo "No Managed Policies" || echo -e "${CYAN}Managed Policies${NC}:\n$MANAGEDPOLICYARNS"
      #find user inline policies, if none set deleted to true
      INLINEPOLICYARNS=$(aws --profile $p iam list-user-policies --user-name ${IAMUSER} | jq -r '.PolicyNames[]' 2>/dev/null)
      [[ -z "$INLINEPOLICYARNS" ]] && INLINEPOLICYARNSDELETED="y" && echo "No Inline Policies" || echo -e "${CYAN}Inline Policies${NC}:\n$INLINEPOLICYARNS"
      #find user groups, if none set deleted to true
      IAMUSERGROUPS=$(aws --profile $p iam list-groups-for-user --user-name ${IAMUSER} | jq -r '.Groups[].GroupName' 2>/dev/null)
      [[ -z "$IAMUSERGROUPS" ]] && IAMUSERGROUPSDELETED="y" && echo "No User Groups" || echo -e "${CYAN}Groups${NC}:\n$IAMUSERGROUPS"
      #find users access/secret keypairs and show status, if none set deleted to true
      ACCESSKEYSSTATUS=$(aws --profile $p iam list-access-keys --user-name ${IAMUSER} | jq -r '.AccessKeyMetadata[] | [.AccessKeyId,.Status]  | @tsv ' 2>/dev/null)
      ACCESSKEYS=$(aws --profile $p iam list-access-keys --user-name ${IAMUSER} | jq -r '.AccessKeyMetadata[] | .AccessKeyId' 2>/dev/null)
      [[ -z "$ACCESSKEYS" ]] && ACCESSKEYSDELETED="y" && echo "No Access Keys" || echo -e "${CYAN}Access Keys${NC}:\n$ACCESSKEYSSTATUS"
      #find login profile, if none set deleted to true
      LOGINPROFILE=$(aws --profile $p iam get-login-profile --user-name ${IAMUSER} 2>/dev/null)
      [[ -z "$LOGINPROFILE" ]] && LOGINDELETED="y" && echo "No Login Profile" || echo "Login Profile exists"
      #find mfa devices, if none, set deleted to true
      MFADEVICE=$(aws --profile $p iam list-virtual-mfa-devices | jq -r '.[][] | .User.UserName' | grep ${IAMUSER} 2>/dev/null)
      MFADEVICESERIAL=$(aws --profile $p iam list-virtual-mfa-devices | jq -r '.[][] | .SerialNumber' | grep ${IAMUSER} 2>/dev/null)
      [[ -z "$MFADEVICE" ]] && MFADELETED="y" && echo "No MFA Device" || echo "MFA Device attached"

      #disable rather than deleting user
      if [[ $DISABLEIAMUSER = "y" ]]; then
        if [[ ! -z "$LOGINPROFILE" ]]; then
          echo "Disabling login..."
          aws --profile $p iam delete-login-profile --user-name ${IAMUSER} 2>/dev/null
        fi
        if [[ ! -z "$ACCESSKEYS" ]]; then
          echo "Disabling keys..."
          for key in $ACCESSKEYS; do
            aws --profile $p iam update-access-key --access-key ${key} --user-name ${IAMUSER} --status Inactive 2>/dev/null
          done
        fi
      fi

      #completely delete user
      if [[ $CONFIRMDELETEIAMUSER = "y" ]]; then
        echo "Deleting..."
        if [[ ! -z "$MANAGEDPOLICYARNS" ]]; then
          for managedpolicy in $MANAGEDPOLICYARNS; do
            aws --profile $p iam detach-user-policy --user-name ${IAMUSER} --policy-arn ${managedpolicy}
          done
          MANAGEDPOLICYARNSDELETED="y"
        fi
        if [[ ! -z "$INLINEPOLICYARNS" ]]; then
          for inlinepolicy in $INLINEPOLICYARNS; do
            aws --profile $p iam delete-user-policy --user-name ${IAMUSER} --policy-name ${inlinepolicy}
          done
          INLINEPOLICYARNSDELETED="y"
        fi
        if [[ ! -z "$IAMUSERGROUPS" ]]; then
          for group in $IAMUSERGROUPS; do
            aws --profile $p iam remove-user-from-group --user-name ${IAMUSER} --group-name ${group}
          done
          IAMUSERGROUPSDELETED="y"
        fi
        if [[ ! -z "$ACCESSKEYS" ]]; then
          for key in $ACCESSKEYS; do
            aws --profile $p iam delete-access-key --access-key ${key} --user-name ${IAMUSER};
          done
          ACCESSKEYSDELETED="y"
        fi
        if [[ ! -z "$LOGINPROFILE" ]]; then
          aws --profile $p iam delete-login-profile --user-name ${IAMUSER}
          LOGINDELETED="y"
        fi
        if [[ ! -z "$MFADEVICE" ]]; then
          aws --profile $p iam deactivate-mfa-device --user-name ${IAMUSER} --serial-number ${MFADEVICESERIAL}
          aws --profile $p iam delete-virtual-mfa-device --serial-number ${MFADEVICESERIAL}
          MFADELETED="y"
        fi
        if [[ MFADELETED="y" ]] && [[ LOGINDELETED="y" ]] && [[ ACCESSKEYSDELETED="y" ]] && [[ IAMUSERGROUPSDELETED="y" ]] && [[ INLINEPOLICYARNSDELETED="y" ]] && [[ INLINEPOLICYARNSDELETED="y" ]] && [[ MANAGEDPOLICYARNSDELETED="y" ]]; then
          aws --profile $p iam delete-user --user-name ${IAMUSER}
          echo "${IAMUSER} deleted"
        fi
      fi
    done
  else
    echo -n "."
  fi
done
echo ""

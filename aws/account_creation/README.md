# AWS_Account_Automation
Automation of the JayBot

## You will need
 * Correctly configured aws cli tool installed
 * Credentials with Organisations permissions on the Billing account (324919260230) 
 * For running the follow up post_account_creation script: a valid, local set of secadmin-prod credentials
 * For running the GuardDuty setup scripts: a working installation of CHAIM and permissions to secadmin-prod & the newly created account and a file called accounts.txt containing the new account number and the new account name, space separated e.g. 012345678901 example-account

## Usage

```
./aws_account_setup.sh -p <billing_account_credentials_profile_name> -n <new_account_name> -u <admin_user_username>
echo "new_account_number new_account_name" > guardduty/accounts.txt
./guardduty/gc_invite_and_accept.sh
```
## To do 

 * Add tags to the cloudformation stacks

#!/bin/bash
#######################################
# In case of any errors (e.g. MySQL) just re-run the script. Nothing will be re-installed except for the packages with errors.
#######################################
#  Written By Anoop Singh from https://www.hostingshades.com/

#COLORS
# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Default Credentials
ADMIN_DEF="admin"               # Defualt suitecrm admin user name
ADMINPASS_DEF="admin@12345"     # Defualt suitecrm pass name
Date=`date`                     # Current date
UNSC="_"                        # For Underscore 
DB_NAME_PREFIX="tenant_"
DNS_SUFFIX="circlecrm.cloud"
DB_PASS_DEF="PassW0rd!"
DB_USER_DEF="suite_adm"
# SUITECRM 
SUITECRM_EXT_URL="https://suitecrm.com/download/128/suite82/561615/suitecrm-8-2-0-zip.zip"
SUITECRM_FILE="suitecrm-8-2-0-zip.zip"
SUITECRM_VER="8.2.0"            # Latest stable version of SuiteCRM from https://github.com/salesagility/SuiteCRM-Core.git/

# Check if running as root  
 if [ "$(id -u)" != "0" ]; then  
   echo -e "$BRed This script must be run as root $Color_Off" 1>&2  
   exit 1  
 fi  



#.2....###### READING DATA FROM USER ######
echo -en "$BWhite \n Please Enter SuiteCRM Company Name                        :$BGreen"
read COMPANY_LOWER


# echo -en "$BWhite \n Please Enter SuiteCRM Domain Name Or DNS Name/Entry       :$BGreen"
# read DOMAIN_NAME

echo -e "$BCyan-----------------------------Printing Databases ------------------------------------$Color_Off"
sleep 2   
                    
 
##################### Start Print Databases and Suggest ##################

db_list=$(mysql -u root -e "SHOW DATABASES LIKE 'tenant%';"  | grep -o 'tenant_[^\s]\+' )

# echo $db_list
if [[ ${db_list} ]]; then

   echo  -e "$BYellow TENANT ID": "COMPANY NAME $Color_Off"
while IFS="  " read -r dbname
do

   sys_name=$(mysql -u root -e "USE $dbname; SELECT * from config WHERE category = 'system' and name ='name'; " \
           | sed -n -e 's/system\s\+name\s\+\(\S\+\)/\1/p' )

   # here database name  $dbname inside $sys_name il valore (p.es. "tenant_1_company")
   # so stdout to the console
   
   echo  -e "$BYellow $dbname": "$sys_name $Color_Off"

done <<< "$db_list"
else
 echo -e "$BRed Sorry: no tenant databases found $Color_Off"
fi
# suggest empty tenant

nsugg=''
for n in {1..10}
do
   if ! echo "$db_list" | tr ' ' '\n' | grep -q -x tenant_$n ; then
      n_sugg=$n
      break
   fi
done

if [ -z "$n_sugg" ]; then
   echo -e "$BWhite Sorry: no space for new tenant $Color_Off"
else
   echo -e "$BWhite Suggested new tenant: $BYellow tenant_$n_sugg $Color_Off"
fi

##################### End Print Databases and Suggest ##################
DB_NAME_LOWER_DEF="tenant_$n_sugg"
echo -en "$BWhite Please Enter SuiteCRM Databases Name              $BYellow[$DB_NAME_LOWER_DEF]:$BGreen"        #tenant_$n_sugg
read DB_NAME_LOWER
DB_NAME_LOWER="${DB_NAME_LOWER:-$DB_NAME_LOWER_DEF}"


echo -en "$BWhite Please Enter SuiteCRM Databases Username $BYellow[default $DB_USER_DEF]:$BGreen"
read DB_USER_LOWER
DB_USER_LOWER="${DB_USER_LOWER:-$DB_USER_DEF}"

echo -en "$BWhite Please Enter SuiteCRM Databases Password $BYellow[default $DB_PASS_DEF]:$BGreen"
read DB_PASSWD
DB_PASSWD="${DB_PASSWD:-$DB_PASS_DEF}"

echo -en "$BWhite Please Enter SuiteCRM Admin Name             $BYellow[default $ADMIN_DEF]:$BGreen"
read ADMIN
ADMIN="${ADMIN:-$ADMIN_DEF}"

echo -en "$BWhite Please Enter SuiteCRM Admin Password$BYellow   [default $ADMINPASS_DEF]:$BGreen"
read ADMINPASS
ADMINPASS="${ADMINPASS:-$ADMINPASS_DEF}"
echo -e "$Color_Off"

################ SUITECRM SCRIPT CREATION - READ_ONLY USER
USER_READONLY_PREFIX_DEF="view_$DB_NAME_LOWER_DEF"   # Default suitecrm user read-only name
PASS_READONLY_DEF="Su1t32022!"     # Default suitecrm user read-only pass name
while true; 
do
echo -en "$BWhite Do you want create a read only user for this tenant?   ..... Y/N: $BGreen"
read READ_ONLY

case $READ_ONLY in
        y|Y|yes|Yes|YES) 
        echo -en "$BWhite Please Enter Tenant Read Only Username $BYellow[default $USER_READONLY_PREFIX_DEF]:$BGreen"
        read USER_READONLY
        USER_READONLY="${USER_READONLY:-$USER_READONLY_PREFIX_DEF}"

        echo -en "$BWhite Please Enter Tenant Read-only Password $BYellow[default $PASS_READONLY_DEF]:$BGreen"
        read PASS_READONLY
        PASS_READONLY="${PASS_READONLY:-$PASS_READONLY_DEF}"

        break;;



        n|N|no|No|NO) echo -e "$Color_Off"
        break;;
 
        *) echo -e "$BYellow Wrong Input ! Please Answer Yes or No $Color_Off" 
 
esac
done
####################

# LOWERCASE
COMPANY=${COMPANY_LOWER,,}
DB_NAME=${DB_NAME_LOWER,,}
DB_USER=${DB_USER_LOWER,,}

#DB_NAME="tenant_$n_sugg" #$DB_NAME_PREFIX$DB_NAME" #####$UNSC$COMPANY"
#DB_USER="$DB_USER"
DNS="$COMPANY.$DNS_SUFFIX"

echo -e "$BCyan------------------------------- SUMMARY OF INSTALLATION ---------------------------------$Color_Off"

echo -en "$BGreen \n SuiteCRM Version            :$BYellow $SUITECRM_VER $Color_Off"
echo -en "$BGreen \n Company Name                :$BYellow $COMPANY $Color_Off"
echo -en "$BGreen \n SuiteCRM DNS Name           :$BYellow $DNS $Color_Off"
echo -en "$BGreen \n SuiteCRM Databases Name     :$BYellow $DB_NAME $Color_Off"
echo -en "$BGreen \n SuiteCRM Databases Username :$BYellow $DB_USER $Color_Off"
echo -en "$BGreen \n SuiteCRM Databases Password :$BYellow $DB_PASSWD $Color_Off"
echo -en "$BGreen \n SuiteCRM Admin Name         :$BYellow $ADMIN $Color_Off"
echo -en "$BGreen \n SuiteCRM Admin Password     :$BYellow $ADMINPASS $Color_Off"
case $READ_ONLY in
        y|Y|yes|Yes|YES) 
echo -en "$BGreen \n Tenant Read Only Username   :$BYellow $USER_READONLY $Color_Off"
echo -en "$BGreen \n Tenant Read-only Password :$BYellow $PASS_READONLY $Color_Off"
echo -e "$Color_Off"
break ;;

n|N|no|No|NO) echo -e "$Color_Off"
        break;;
esac


#.3..##### Installing SuiteCRM.....
while true; 
do
echo -en "$BWhite \n Do You Want Install SuiteCRM  ..... Y/N: $BGreen"
read suite

case $suite in
        y|Y|yes|Yes|YES) 
      
echo -e "$BCyan----------------------------- Creating Vhost for The Domain -----------------------------$Color_Off"        
sleep 2

FILE=/etc/httpd/conf.d/$DNS.conf     
if [ -f $FILE ]; then
     
     while true; do
        echo -e "$BRed File $DNS.conf already exists. Unable to create Vhost for the Domain $Color_Off" 1>&2 
        echo -en "$BWhite Do you want to overwrite the file  .....Yes/No : $BYellow"
        
        read overwrite
        case $overwrite in
        [yY][eE][sS]|[yY]) 
   echo "<VirtualHost *:80>
    ServerAdmin $COMPANY@$DNS_SUFFIX
    DocumentRoot "/var/www/html/$COMPANY/public"
    DirectoryIndex index.php index.php4 index.php5 index.htm index.html
    ServerName $DNS
    ErrorLog "/var/log/httpd/$COMPANY.error_log"
    CustomLog "/var/log/httpd/$COMPANY.access_log" common
    
<Directory /var/www/html/$COMPANY/public>
    AllowOverride All
    Order Allow,Deny
    Allow from All
</Directory>

</VirtualHost>
    " >/etc/httpd/conf.d/$DNS.conf    
        
        break;;
        [nN][oO]|[nN])  echo -en "$Color_Off"
        exit;;
        *) echo -e "$BYellow Wrong Input ! Please Answer Yes or No $Color_Off" 
    esac
done

   
else
   echo "<VirtualHost *:80>
    ServerAdmin $COMPANY@$DNS_SUFFIX
    DocumentRoot "/var/www/html/$COMPANY/public"
    DirectoryIndex index.php index.php4 index.php5 index.htm index.html
    ServerName $DNS
    ErrorLog "/var/log/httpd/$COMPANY.error_log"
    CustomLog "/var/log/httpd/$COMPANY.access_log" common
    
<Directory /var/www/html/$COMPANY/public>
    AllowOverride All
    Order Allow,Deny
    Allow from All
</Directory>

</VirtualHost>
    " >/etc/httpd/conf.d/$DNS.conf
fi


#.4..################## Create Databases and User ##################################

echo -e "$BCyan------------------------ Creating Databases and User for SuiteCRM -----------------------$Color_Off"
sleep 2

 RESULT=`mysql -u root -e "SHOW DATABASES" | grep $DB_NAME`
 if [ "$RESULT" == "$DB_NAME" ]; then
    mysqldump -u root $DB_NAME > "/root/db-$DB_NAME-$(date +%s).sql"
  

 fi

 echo -e "$BYellow The Database Name $DB_NAME Has Been Created Successfully! $Color_Off"
    
    mysql -u root  -e "DROP DATABASE IF EXISTS $DB_NAME;"
    mysql -u root  -e "CREATE DATABASE $DB_NAME";
    mysql -u root  -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWD'";
    mysql -u root  -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'";
    mysql -u root  -e "FLUSH PRIVILEGES";
 
echo -e "$BCyan---------------------------Installing SuiteCRM for $DNS -------------------------$Color_Off"
sleep 2   
    cd /opt
    
    rm -rf $COMPANY > suite.log
    mkdir $COMPANY && cd $COMPANY
    wget -qc $SUITECRM_EXT_URL
    unzip $SUITECRM_FILE > suite-unzip.log

    find . -type d -not -perm 2755 -exec chmod 2755 {} \;
    find . -type f -not -perm 0644 -exec chmod 0644 {} \;
    find . ! -user apache -exec chown apache:apache {} \;
    chmod +x bin/console
    service httpd restart
    rm -rvf $SUITECRM_FILE
echo -e "$BCyan---------------------------SuiteCRM Silent Install -------------------------$Color_Off"


    ./bin/console suitecrm:app:install -u "$ADMIN" -p "$ADMINPASS" -U "$DB_USER" -P "$DB_PASSWD" -H "localhost" -N "$DB_NAME" -S "https://$DNS" -d "yes" > suitecrmdatabases.log
    
    cd /var/www/html
    
    ln -sf -T /opt/$COMPANY /var/www/html/$COMPANY
    cd /var/www/html/$COMPANY
    find . -type d -not -perm 2755 -exec chmod 2755 {} \;
    find . -type f -not -perm 0644 -exec chmod 0644 {} \;
    find . ! -user apache -exec chown apache:apache {} \;
    sudo chown -R apache:apache /var/www/html

echo -en "$BGreen \n SuiteCRM Link      : $BYellow http://$DNS $Color_Off"
echo -en "$BGreen \n SuiteCRM Admin User: $BYellow $ADMIN $Color_Off"
echo -e "$BGreen \n SuiteCRM Admin Pass : $BYellow $ADMINPASS $Color_Off"

echo -e "$BGreen \n SuiteCRM And Databases Details Have been Stored In $BYellow /var/www/html/$DNS.txt $Color_Off"

echo "Creaction Date is: $Date
SuiteCRM_Admin_Details:
SuiteCRM Link:http://$DNS
SuiteCRM Admin User:$ADMIN 
SuiteCRM Admin Pass:$ADMINPASS

DataBases_Details:
Databases Name:  $DB_NAME
Database UserName:$DB_USER
Database Password:$DB_PASSWD
" >/var/www/html/$DNS.txt
sudo chown -R apache:apache /var/www/html

    break;;



        n|N|no|No|NO) echo -e "$Color_Off"
        exit;;
 
        *) echo -e "$BYellow Wrong Input ! Please Answer Yes or No $Color_Off" 
 
esac
done

#.5.################# Install Let’s Encrypt with Apache ###########################
 
while true; do
 DIR=/etc/letsencrypt/live/$DNS
 echo -en "$BWhite Do you want to install SSL ? Yes or No ...: $BGreen"
 read ssl
 
      case $ssl in
            [yY][eE][sS]|[yY])
echo -e "$BCyan------------------------ Installing Let's Encrypt for $DNS ----------------------$Color_Off"
sleep 2                          
    echo -en "$BWhite Enter a valid e-mail for let's encrypt certificate: $BYellow"
	read EMAIL_NAME

                        certbot --apache -n --agree-tos -m "$EMAIL_NAME" -d $DNS
                            
                            
                              if [ -d $DIR ]; then
                              echo -e "$BGreen SSL Installation Successfully Completed $Color_Off"
                              break 1
                              
                              else
                              echo -e "$BRed  SSL installation has been failed $Color_Off"
                              
                              fi
                              
                           echo -e "$Color_Off" ;;
            
            [nN][oO]|[nN]) echo -e "$Color_Off"
             break;;
    
            *) echo -e "$BYellow Wrong Input ! Please Answer Yes or No $Color_Off" 

      esac 
done


case $READ_ONLY in
                y|Y|yes|Yes|YES) 

                    mysql -u root  -e "CREATE USER '$USER_READONLY'@'%' IDENTIFIED BY '$PASS_READONLY'";
                    mysql -u root  -e "GRANT SELECT ON $DB_NAME.* TO '$USER_READONLY'@'%'";
                    mysql -u root  -e "FLUSH PRIVILEGES";
                    break;;

                n|N|no|No|NO) echo -e "$Color_Off"
                break;;
esac

########################  END #####################################################


#!/bin/bash
#  Written By Anoop Singh from https://www.hostingshades.com/

#COLORS
# Reset
Color_Off='\033[0m'       # Text Reset

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
DB_NAME_PREFIX="tenant_"
DNS_SUFFIX="circlecrm.cloud"
DB_PASS_DEF="PassW0rd!"
DB_USER_DEF="suite_adm"

# Deafult value
SUITECRM_DEFF="1" # suitecrm 7

# SUITECRM 
SUITECRM_EXT_URL_8="https://suitecrm.com/download/128/suite82/561615/suitecrm-8-2-0-zip.zip"
SUITECRM_FILE_8="suitecrm-8-2-0-zip.zip"
SUITECRM_VER_8="8.2.0"

SUITECRM_EXT_URL_7="https://suitecrm.com/download/137/suite712/561718/suitecrm-7-12-8"
SUITECRM_FILE_7="suitecrm-7-12-8"
SUITECRM_DIR="SuiteCRM-7.12.8"
SUITECRM_VER_7="7.12.8"

# Check if running as root  
if ! [ "$(id -u)" = 0 ]; then echo -e "$BRed This script must be run as sudo or root, try again..."; exit 1; fi

while true; do
        echo -e "$BCyan------------------------ Please Select SuiteCRM Version ----------------------------$Color_Off"
        echo -en "$BGreen       1. SuiteCRM 7      2. SuiteCRM 8     3.Cancel $BWhite[Deafult Is SuiteCRM 7]:$BYellow"
        read SUITECRM
        SUITECRM="${SUITECRM:-$SUITECRM_DEFF}"
   case $SUITECRM in
        1) break;;
        2) break;;
        3) echo -e "$Color_Off" 
        exit;;
        *) echo -e "$BYellow Wrong Input ! Please Answer 1 ,2 or 3 $Color_Off" ;;
    esac

done

####### READING DATA FROM USER ######
echo -en "$BWhite \n Please Enter SuiteCRM Company Name                        :$BGreen"
read COMPANY_LOWER


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
 echo -e "$BWhite Sorry: no tenant databases found $Color_Off"
fi

# suggest empty tenant

nsugg=''
for n in {1..100}
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
PASS_READONLY_DEF="Su1t32022!"                       # Default suitecrm user read-only pass name
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

# Remove space 
shopt -s extglob
COMPANY="${COMPANY//+([[:space:]])/}"

#DB_NAME="tenant_$n_sugg" #$DB_NAME_PREFIX$DB_NAME" #####$UNSC$COMPANY"
#DB_USER="$DB_USER"
DNS="$COMPANY.$DNS_SUFFIX"
if [[ ${SUITECRM} == "1" ]]; then SUITECRM_VER="7.12.8"; else SUITECRM_VER="8.2.0"; fi

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



vhost7 (){
    echo "<VirtualHost *:80>
    # SuiteCRM 7
    ServerAdmin $COMPANY@$DNS_SUFFIX
    DocumentRoot "/var/www/html/$COMPANY"
    DirectoryIndex index.php index.php4 index.php5 index.htm index.html
    ServerName $DNS
    ErrorLog "/var/log/httpd/$COMPANY.error_log"
    CustomLog "/var/log/httpd/$COMPANY.access_log" common
    
<Directory /var/www/html/$COMPANY>
    AllowOverride All
    Order Allow,Deny
    Allow from All
</Directory>

</VirtualHost>
    " >/etc/httpd/conf.d/$DNS.conf
}

vhost8 (){
    echo "<VirtualHost *:80>
    # SuiteCRM 8
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
}

vhost_if_else (){
    if [[ ${SUITECRM} == "1" ]]; then vhost7; else vhost8; fi
}

remove_vhost (){
rm -rvf /etc/httpd/conf.d/$DNS*
}

creating_vhost (){
echo -e "$BCyan----------------------------- Creating Vhost for The Domain -----------------------------$Color_Off"        
sleep 2
FILE=/etc/httpd/conf.d/$DNS.conf     
if [ -f $FILE ]; then
    
    while true; do
        echo -e "$BRed File $DNS.conf already exists. Unable to create Vhost for the Domain $Color_Off" 1>&2 
        echo -en "$BWhite Do you want to overwrite the file  .....Yes/No : $BYellow"
        
        read overwrite
        case $overwrite in
            [yY][eE][sS]|[yY]) remove_vhost; vhost_if_else; break;;
            [nN][oO]|[nN])  echo -en "$Color_Off" ; exit;;
            *) echo -e "$BYellow Wrong Input ! Please Answer Yes or No $Color_Off" 
        esac
    done
 
 else vhost_if_else; fi

}

mysql_installation (){
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

}

suitecrm_8_file_downloading (){
    echo -e "$BCyan---------------------------Installing SuiteCRM for $DNS -------------------------$Color_Off"
sleep 2   
cd /opt
rm -rf $COMPANY > /dev/null
mkdir $COMPANY && cd $COMPANY
wget -qc $SUITECRM_EXT_URL_8
unzip $SUITECRM_FILE_8 > suite-unzip.log

find . -type d -not -perm 2755 -exec chmod 2755 {} \;
find . -type f -not -perm 0644 -exec chmod 0644 {} \;
find . ! -user apache -exec chown apache:apache {} \;
chmod +x bin/console
service httpd restart > /dev/null
rm -rvf $SUITECRM_FILE_8
}

suitecrm_7_file_downloading (){
    echo -e "$BCyan---------------------------Installing SuiteCRM for $DNS -------------------------$Color_Off"
sleep 2   
    cd /opt
    rm -rf $COMPANY > /dev/null
    wget -qc $SUITECRM_EXT_URL_7
    unzip $SUITECRM_FILE_7 > suite-unzip.log
    
    mv $SUITECRM_DIR $COMPANY
    cd $COMPANY
    
    find . -type d -not -perm 2755 -exec chmod 2755 {} \;
    find . -type f -not -perm 0644 -exec chmod 0644 {} \;
    find . ! -user apache -exec chown apache:apache {} \;
    chmod -R 775 cache custom modules themes data upload
    chmod 775 config_override.php 2>/dev/null
    ln -sf -T /opt/$COMPANY /var/www/html/$COMPANY
    sudo chown -R apache:apache /var/www/html
    service httpd restart > /dev/null
    rm -rvf /opt/$SUITECRM_FILE_7 > /dev/null
}

suitecrm7_installation_instruction (){
    echo -e "$BCyan Go to Browser and run https://$DNS  and Follow Instruction   $Color_Off"
    echo -en "$BGreen \n URL of SuiteCRM Instance           :$BYellow https://$DNS $Color_Off"
    echo -en "$BGreen \n SuiteCRM Databases Host Name       :$BYellow localhost $Color_Off"
    echo -en "$BGreen \n SuiteCRM Databases Name            :$BYellow $DB_NAME $Color_Off"
    echo -en "$BGreen \n SuiteCRM Databases Username        :$BYellow $DB_USER $Color_Off"
    echo -en "$BGreen \n SuiteCRM Databases Password        :$BYellow $DB_PASSWD $Color_Off"
    echo -en "$BGreen \n SuiteCRM Admin Name                :$BYellow $ADMIN $Color_Off"
    echo -en "$BGreen \n SuiteCRM Admin Password            :$BYellow $ADMINPASS $Color_Off"
    
}

suitecrm8_silent_install (){
echo -e "$BCyan---------------------------SuiteCRM Silent Install -------------------------$Color_Off"
cd /opt/$COMPANY
./bin/console suitecrm:app:install -u "$ADMIN" -p "$ADMINPASS" -U "$DB_USER" -P "$DB_PASSWD" -H "localhost" -N "$DB_NAME" -S "https://$DNS" -d "yes" > suitecrmdatabases.log
ln -sf -T /opt/$COMPANY /var/www/html/$COMPANY
 cd /var/www/html/$COMPANY
 find . -type d -not -perm 2755 -exec chmod 2755 {} \;
 find . -type f -not -perm 0644 -exec chmod 0644 {} \;
 find . ! -user apache -exec chown apache:apache {} \;
 sudo chown -R apache:apache /var/www/html
}

print_details (){
    echo -en "$BGreen \n SuiteCRM Link                      :$BYellow http://$DNS $Color_Off"
    echo -en "$BGreen \n SuiteCRM Admin User                :$BYellow $ADMIN $Color_Off"
    echo -en "$BGreen \n SuiteCRM Admin Pass                :$BYellow $ADMINPASS $Color_Off"

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

}

ssl_cheking (){
    DIR=/etc/letsencrypt/live/$DNS
    if [ -d $DIR ]; then echo -e "$BGreen SSL Installation Successfully Completed $Color_Off"; break 1
    else echo -e "$BRed  SSL installation has been failed $Color_Off"; fi
}

letsencrypt_install (){
while true; do
 echo -en "$BWhite Do you want to install SSL ? Yes or No ...: $BGreen"
 read ssl
    case $ssl in
     [yY][eE][sS]|[yY])
     echo -e "$BCyan------------------------ Installing Let's Encrypt for $DNS ----------------------$Color_Off"
     sleep 2                          
     echo -en "$BWhite Enter a valid e-mail for let's encrypt certificate: $BYellow"
	 read EMAIL_NAME
     echo -e "$Color_Off"
     certbot --apache -n --agree-tos -m "$EMAIL_NAME" -d $DNS
     ssl_cheking ;;
     [nN][oO]|[nN]) echo -e "$Color_Off"
     break;;
    
     *) echo -e "$BYellow Wrong Input ! Please Answer Yes or No $Color_Off" 

    esac 
done

}

read_only_user (){
    case $READ_ONLY in
   y|Y|yes|Yes|YES) 
  RESULT=`mysql -u root  -e "SELECT user FROM mysql.user" | grep $USER_READONLY;`
  if [[ ${RESULT} ]]; then
  mysql -u root  -e "DROP USER '$USER_READONLY';"
  fi

 mysql -u root  -e "CREATE USER '$USER_READONLY'@'%' IDENTIFIED BY '$PASS_READONLY'";
 mysql -u root  -e "GRANT SELECT ON $DB_NAME.* TO '$USER_READONLY'@'%'";
 mysql -u root  -e "FLUSH PRIVILEGES";
 
 sudo firewall-cmd --permanent --add-port=3306/tcp
 sudo firewall-cmd --reload
 break;;

 n|N|no|No|NO) echo -e "$Color_Off"
 break;;
esac

}

#.3..##### Installing SuiteCRM.....
choose_sutecrm (){
    if [[ ${SUITECRM} == "1" ]]; then suitecrm_7_file_downloading; suitecrm7_installation_instruction; else suitecrm_8_file_downloading; suitecrm8_silent_install; fi
}

suitecrm_installation (){
while true; 
do
    echo -en "$BWhite \n Do You Want Install SuiteCRM  ..... Y/N: $BGreen"
    read SUITECRM_CONFIRMATION
    case $SUITECRM_CONFIRMATION in
        [yY][eE][sS]|[yY]) creating_vhost; mysql_installation; choose_sutecrm; print_details; break;;
        [nN][oO]|[nN]) echo -e "$Color_Off"; exit;;
        *) echo -e "$BYellow Wrong Input ! Please Answer Yes or No $Color_Off" 
    
    esac
done

}

suitecrm_installation
letsencrypt_install
read_only_user


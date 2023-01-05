#!/bin/bash
#Written By Anoop Singh from https://www.hostingshades.com/
#COLORS
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
Date=$(date)                    # Current date
DB_NAME_PREFIX="tenant_"
DNS_SUFFIX="circlecrm.cloud"
DB_PASS_DEF="PassW0rd!"
DB_USER_DEF="suite_adm"
PASS_READONLY_DEF="Su1t32022!"                       # Default suitecrm user read-only pass name

# Deafult value
PING_DEFF="yes"
SUITECRM_DEFF="1" # suitecrm 7
LOG_FILE="/opt/$COMPANY"

# SUITECRM Installation URL
SUITECRM_EXT_URL_8="https://suitecrm.com/download/128/suite82/561615/suitecrm-8-2-0-zip.zip"
SUITECRM_FILE_8="suitecrm-8-2-0-zip.zip"
SUITECRM_VER_8="8.2.0"

SUITECRM_EXT_URL_7="https://suitecrm.com/download/137/suite712/561718/suitecrm-7-12-8"
SUITECRM_FILE_7="suitecrm-7-12-8"
SUITECRM_DIR="SuiteCRM-7.12.8"
SUITECRM_VER_7="7.12.8"

# Check if running as root  
if ! [ "$(id -u)" = 0 ]; then echo -e "$BRed This script must be run as sudo or root, try again..."; exit 1; fi

choose_sutecrm_menu (){
while true; do
     echo -e "$BCyan------------------------ Please Select SuiteCRM Version ----------------------------$Color_Off"
     echo -en "$BGreen       1. SuiteCRM 7      2. SuiteCRM 8     3.Cancel $BWhite [Deafult Is SuiteCRM 7]:$BYellow"
     read SUITECRM
     SUITECRM="${SUITECRM:-$SUITECRM_DEFF}"
    case $SUITECRM in
        1) SUITECRM="SUITECRM_VER_7"; break;;
        2) SUITECRM="SUITECRM_VER_8"; break;;
        3) echo -e "$Color_Off"; exit;;
        *) echo -e "$BYellow Wrong Input ! Please Answer 1 ,2 or 3 $Color_Off" ;;
    esac

done
 
}

print_tenant (){
 echo -e "$BCyan-----------------------------Printing Databases ------------------------------------$Color_Off"
 db_list=$(mysql -u root -e "SHOW DATABASES LIKE 'tenant%';"  | grep -o 'tenant_[^\s]\+' )

    if [[ ${db_list} ]]; then
        echo  -e "$BYellow TENANT ID": "COMPANY NAME $Color_Off"
        while IFS="  " read -r dbname
        do
        sys_name=$(mysql -u root -e "USE $dbname; SELECT * from config WHERE category = 'system' and name ='name'; " \
            | sed -n -e 's/system\s\+name\s\+\(\S\+\)/\1/p' )
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
    DB_NAME_LOWER_DEF="tenant_$n_sugg"
}

mysql_data () {
    while true; do  
        echo -en "$BWhite Please Enter SuiteCRM Databases Name              $BYellow[$DB_NAME_LOWER_DEF]:$BGreen"        #tenant_$n_sugg
        read DB_NAME_LOWER
        DB_NAME_LOWER="${DB_NAME_LOWER:-$DB_NAME_LOWER_DEF}"
        DB_NAME=${DB_NAME_LOWER,,}
        USER_READONLY_PREFIX_DEF="view_$DB_NAME"
        
        DB_RESULT=$(mysql -u root -e "SHOW DATABASES" | grep $DB_NAME)
        if [[ ! ${DB_RESULT} ]]; then  break
        else echo -e "$BYellow Databases $DB_NAME Already Exist  $Color_Off"; fi
    done

    
        echo -en "$BWhite Please Enter SuiteCRM Databases Username $BYellow[default $DB_USER_DEF]:$BGreen"
        read DB_USER_LOWER
        DB_USER_LOWER="${DB_USER_LOWER:-$DB_USER_DEF}"
        DB_USER=${DB_USER_LOWER,,}
        
    echo -en "$BWhite Please Enter SuiteCRM Databases Password $BYellow[default $DB_PASS_DEF]:$BGreen"
    read DB_PASSWD
    DB_PASSWD="${DB_PASSWD:-$DB_PASS_DEF}" 
}


# READING DATA FROM USER ######

company_name (){
while true; do    
echo -en "$BWhite \n Please Enter SuiteCRM Company Name                        :$BGreen"
   read COMPANY_LOWER
   COMPANY=${COMPANY_LOWER,,}
   shopt -s extglob
   COMPANY="${COMPANY//+([[:space:]])/}" 
   DNS="$COMPANY.$DNS_SUFFIX"
   LOG_FILE="/opt/$COMPANY"
   
   if [[ ! -z "$COMPANY_LOWER" ]]; then  break 
   else  echo -e "$BYellow Company Name not be empty $Color_Off" ; fi
done   
}

ping_domain (){
 while true; do
   echo -en "$BWhite Do you want to ping $DNS $BYellow[Deafult Is Yes]: $BGreen"
   read PING
   PING="${PING:-$PING_DEFF}"
   
      case $PING in
         [yY][eE][sS]|[yY]) 
         
            ping=$(ping -c 3 ${DNS})
               if [[ ${ping} ]]; then echo -e "$BGreen $DNS is reachable successfully" ; break
               else 
               echo -e " $BYellow $DNS is unreachable "
                 company_name
               fi
               
           
         echo  -e "$Color_Off" ;; 
         [nN][oO]|[nN])  break;;
          *) echo -e "$BYellow Wrong Input ! Please Answer Yes or No $Color_Off" 
      esac
  done 
}

read_data_from_user (){
    echo -en "$BWhite Please Enter SuiteCRM Admin Name             $BYellow[default $ADMIN_DEF]:$BGreen"
    read ADMIN
    ADMIN="${ADMIN:-$ADMIN_DEF}"

    echo -en "$BWhite Please Enter SuiteCRM Admin Password$BYellow   [default $ADMINPASS_DEF]:$BGreen"
    read ADMINPASS
    ADMINPASS="${ADMINPASS:-$ADMINPASS_DEF}"
    echo -e "$Color_Off"
}

databases_user_read_only_checking (){
 USER_RESULT1=$(mysql -u root  -e "SELECT user FROM mysql.user" | grep $USER_READONLY;)
 if [[ ! ${USER_RESULT1} ]]; then  break 
 else  echo -e "$BYellow The Databases User $USER_READONLY Already Exist  $Color_Off" ; fi
}


read_only_user_promot () {
    while true; 
    do
    echo -en "$BWhite Do you want create a read only user for this tenant?   ..... Y/N: $BGreen"
    read READ_ONLY

        case $READ_ONLY in
             y|Y|yes|Yes|YES) 
                while true; do
                    echo -en "$BWhite Please Enter Read Only Tenant Username $BYellow[default $USER_READONLY_PREFIX_DEF]:$BGreen"
                    read USER_READONLY
                    USER_READONLY="${USER_READONLY:-$USER_READONLY_PREFIX_DEF}"
                
                    echo -en "$BWhite Please Enter Read-only Tenant Password $BYellow[default $PASS_READONLY_DEF]:$BGreen"
                    read PASS_READONLY
                    PASS_READONLY="${PASS_READONLY:-$PASS_READONLY_DEF}"
                    databases_user_read_only_checking
                done
                break;;
             n|N|no|No|NO) echo -e "$Color_Off"
                break;;
        
             *) echo -e "$BYellow Wrong Input ! Please Answer Yes or No $Color_Off" 
        
        esac
        
    done
}

summary_of_installation (){
 if [[ ${SUITECRM} == "SUITECRM_VER_7" ]]; then SUITECRM_VER="7.12.8"; else SUITECRM_VER="8.2.0"; fi
 echo -e "$BCyan------------------------------- SUMMARY OF INSTALLATION ---------------------------------$Color_Off"

 echo -en "$BGreen \n SuiteCRM Version            :$BYellow $SUITECRM_VER $Color_Off"
 echo -en "$BGreen \n Company Name                :$BYellow $COMPANY $Color_Off"
 echo -en "$BGreen \n SuiteCRM DNS Name           :$BYellow $DNS $Color_Off"
 echo -en "$BGreen \n SuiteCRM Databases Name     :$BYellow $DB_NAME $Color_Off"
 echo -en "$BGreen \n SuiteCRM Databases Username :$BYellow $DB_USER $Color_Off"
 echo -en "$BGreen \n SuiteCRM Databases Password :$BYellow $DB_PASSWD $Color_Off"
 echo -en "$BGreen \n SuiteCRM Admin Name         :$BYellow $ADMIN $Color_Off"
 echo -en "$BGreen \n SuiteCRM Admin Password     :$BYellow $ADMINPASS $Color_Off"
}

read_only_user_print (){
 case $READ_ONLY in
   y|Y|yes|Yes|YES) 
    echo -en "$BGreen \n Tenant Read Only Username   :$BYellow $USER_READONLY $Color_Off"
    echo -en "$BGreen \n Tenant Read-only Password :$BYellow $PASS_READONLY $Color_Off"
    echo -e "$Color_Off"; break ;;
   n|N|no|No|NO) echo -e "$Color_Off" ; break;;
 esac
}


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
    if [[ ${SUITECRM} == "SUITECRM_VER_7" ]]; then vhost7; else vhost8; fi
}

remove_vhost (){
rm -rvf /etc/httpd/conf.d/$DNS* > /dev/null
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

 
mysql -u root  -e "CREATE DATABASE $DB_NAME";
mysql -u root  -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWD'";
mysql -u root  -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'";
mysql -u root  -e "FLUSH PRIVILEGES";
echo -e "$BYellow The Database Name $DB_NAME Has Been Created Successfully! $Color_Off"

} 

suitecrm_8_file_downloading (){
    echo -e "$BCyan---------------------------Installing SuiteCRM for $DNS -------------------------$Color_Off"
sleep 2   
cd /opt
rm -rf $COMPANY > /dev/null
mkdir $COMPANY && cd $COMPANY
wget -qc $SUITECRM_EXT_URL_8
unzip $SUITECRM_FILE_8 > $LOG_FILE/suite-unzip.log

find . -type d -not -perm 2755 -exec chmod 2755 {} \;
find . -type f -not -perm 0644 -exec chmod 0644 {} \;
find . ! -user apache -exec chown apache:apache {} \;
chmod +x bin/console
service httpd restart > /dev/null
rm -rvf $SUITECRM_FILE_8 > /dev/null
}

suitecrm_7_file_downloading (){
    echo -e "$BCyan---------------------------Installing SuiteCRM for $DNS -------------------------$Color_Off"
sleep 2   
    cd /opt
    rm -rf $COMPANY > /dev/null
    wget -qc $SUITECRM_EXT_URL_7
    unzip $SUITECRM_FILE_7 > suite-unzip.log
    
    mv $SUITECRM_DIR $COMPANY
    mv suite-unzip.log $COMPANY/
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
./bin/console suitecrm:app:install -u "$ADMIN" -p "$ADMINPASS" -U "$DB_USER" -P "$DB_PASSWD" -H "localhost" -N "$DB_NAME" -S "https://$DNS" -d "yes" > $LOG_FILE/suitecrm8_silent_install.log
ln -sf -T /opt/$COMPANY /var/www/html/$COMPANY
 cd /var/www/html/$COMPANY
 find . -type d -not -perm 2755 -exec chmod 2755 {} \;
 find . -type f -not -perm 0644 -exec chmod 0644 {} \;
 find . ! -user apache -exec chown apache:apache {} \;
 sudo chown -R apache:apache /var/www/html
}

choose_sutecrm (){
    if [[ ${SUITECRM} == "SUITECRM_VER_7" ]]; then suitecrm_7_file_downloading; suitecrm7_installation_instruction; else suitecrm_8_file_downloading; suitecrm8_silent_install; fi
}

print_details (){
    echo -en "$BGreen \n SuiteCRM Link                      :$BYellow http://$DNS $Color_Off"
    echo -en "$BGreen \n SuiteCRM Admin User                :$BYellow $ADMIN $Color_Off"
    echo -en "$BGreen \n SuiteCRM Admin Pass                :$BYellow $ADMINPASS $Color_Off"

echo -e "$BGreen \n SuiteCRM And Databases Details Have been Stored In $BYellow ${LOG_FILE}/SuiteCRM/${DNS}.txt $Color_Off"
mkdir ${LOG_FILE}/SuiteCRM
echo "Creaction Date is: $Date
SuiteCRM_Admin_Details:
SuiteCRM Link:http://$DNS
SuiteCRM Admin User:$ADMIN 
SuiteCRM Admin Pass:$ADMINPASS

DataBases_Details:
Databases Name:  $DB_NAME
Database UserName:$DB_USER
Database Password:$DB_PASSWD
" >${LOG_FILE}/SuiteCRM/${DNS}.txt
sudo chown -R apache:apache /var/www/html

}

ssl_cheking (){
    DIR=/etc/letsencrypt/live/$DNS
    if [ -d $DIR ]; then echo -e "$BGreen SSL Installation Successfully Completed $Color_Off"; break 1
    else echo -e "$BRed  SSL installation has been failed $Color_Off"; fi
}

LETSENCRYPT_MSG (){
    echo -en "$BYellow \n Please Check A Record For    :$BYellow $DNS $Color_Off"
    echo -en "$BYellow \n Please Check WAN Firewall Ports (HTTP/HTTPS) $Color_Off"
    echo -e "$Color_Off"
    
}

letsencrypt_asking (){
while true; do
 echo -en "$BWhite Do you want to install SSL ? Yes or No ...: $BGreen"
 read ssl
    case $ssl in
     [yY][eE][sS]|[yY]) LETSENCRYPT_MSG; sleep 5 ;
     #read -p "$(echo -e $BYellow Check Firewall Settings and DNS Configuration. Press any key to Resume ...$Color_Off)"
      break ;;
     [nN][oO]|[nN]) echo -e "$Color_Off"
     break;;
     *) echo -e "$BYellow Wrong Input ! Please Answer Yes or No $Color_Off" 
    esac 
done

}

letsencrypt_install (){
while true; do    
    case $ssl in
     [yY][eE][sS]|[yY])
     echo -e "$BCyan------------------------ Installing Let's Encrypt for $DNS ----------------------$Color_Off"
     sleep 2                          
     certbot --apache -n --agree-tos -m "$EMAIL_NAME" -d $DNS 
     ssl_cheking; LETSENCRYPT_MSG; 
     read -p "$(echo -e $BYellow Check Firewall Settings and DNS Configuration. Press any key to Resume ...$Color_Off)"
     sleep 2 ; letsencrypt_asking ;;
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

# Running Funcation

choose_sutecrm_menu
company_name
ping_domain
print_tenant
mysql_data
read_data_from_user
read_only_user_promot
letsencrypt_asking
summary_of_installation
read_only_user_print

suitecrm_installation
letsencrypt_install
read_only_user

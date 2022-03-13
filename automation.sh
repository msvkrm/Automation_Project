#!/bin/bash
myname="vikram"
s3_bucket="upgrad-vikram"

# update package details
sudo apt update -y


# Install the apache2 package if it is not already installed
REQUIRED_PACKAGE1="apache2"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PACKAGE1|grep "install ok installed")
echo Checking for $REQUIRED_PACKAGE1: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  echo "$REQUIRED_PACKAGE1 not installed. Setting up $REQUIRED_PACKAGE1."
  sudo apt-get --yes install $REQUIRED_PACKAGE1
fi


# Install the awscli package if it is not already installed
REQUIRED_PACKAGE2="awscli"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PACKAGE2|grep "install ok installed")
echo Checking for $REQUIRED_PACKAGE2: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  echo "$REQUIRED_PACKAGE2 not installed. Setting up $REQUIRED_PACKAGE2."
  sudo apt-get --yes install $REQUIRED_PACKAGE2
fi


#Ensure that the apache2 service is running and enabled
apache_svc=`systemctl status apache2.service  | grep Active | awk '{ print $3 }'`

if [ $apache_svc == "(dead)" ]
then
        systemctl enable apache2.service
fi

if pgrep -x "apache2" >/dev/null
then
    echo "apache2 service is running"
else
    sudo systemctl start apache2
fi


# Create a tar archive of apache2 access logs and error logs
timestamp="$(date '+%d%m%Y-%H%M%S')"
file_name="/tmp/${myname}-httpd-logs-${timestamp}.tar"

echo "Creating Tar bundle "
tar -cf ${file_name} $( find /var/log/apache2/ -name "*.log")

file_size=$(wc -c $file_name | awk '{print $1}')


# Copy the archive to the s3 bucket
echo "uploading tar bundle to S3"
aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar

echo "Completed uploading tar bundle to S3"


# check for the presence of the inventory.html, else creating one
inventory_file="/var/www/html/inventory.html"

if [[ ! -f $inventory_file ]]; then
    echo "Inventory file not found, creating one" 
    sudo touch $inventory_file
    sudo chmod 777 $inventory_file
    sudo echo "Log Type		Time Created		Type		Size" >> $inventory_file
fi

sudo echo "httpd-logs		$timestamp		tar		$file_size" >> $inventory_file
echo "Inventory file updated"


# create a cron job file in /etc/cron.d/ 
cron_job="/etc/cron.d/automation"
automation_file="/root/Automation_Project/automation.sh"

echo "Checking crontab job"
cron_job_exists=$(sudo crontab -l | grep 'automation')
echo "crontab job exists : $cron_job_exists"

if [[ ! $cron_job_exists ]]; then
	if [[ ! -f  $cron_job ]]; then
		echo "Creating and adding a cron job"
		sudo touch $cron_job
		sudo chmod 777 $cron_job
		sudo echo "00 12 * * * $automation_file" >> $cron_job
	fi
	sudo crontab $cron_job
fi

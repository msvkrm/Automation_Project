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
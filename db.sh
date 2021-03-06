#!/usr/bin/env bash
##############################################################################################################
# HOW TO
#
# Make sure the script has execution permissions
# ./db.sh {magento_root_dir} {s3_bucket_name} {hourly|daily_m|daily_w|single|monthly}
#
# magento_root_dir -> The folder which has the folders app/, media/, var/, skin/.
# s3_bucket_name   -> The S3 Bucket Name that will be used for the backups. Something like domain.com-dbbackup is always a good choice.
# hourly|daily_m|daily_w|single|monthly  -> The type of backup file.
#		If hourly, it will create a file called dbname_hourly_n.tar.gz. Where "n" is the current hour (24 hour format) (1 am is 1, not 01) 
#		If daily_m, it will create a file called dbname_daily_m_nn.tar.gz. Where "nn" is the day of the month
#		If daily_w, it will create a file called dbname_daily_w_nn.tar.gz. Where "nn" is the day of the week
#		If single, it will create a file called dbname_single.tar.gz
#		If monthly, it will create a file called dbname_monthly_nn.tar.gz. Where "nn" is the current month
##############################################################################################################

#TODO: If file is smaller than 5 MB, or file didn't make it to S3, something went wrong: NOTIFY!

#######################################
#Script Behavior Configuration
#######################################

#Set this to 1 to not use S3 (condition at s3_FUNCTIONS())
S3_TEST=0
DEL_TEMPDIR=1

#check arguments count and not empty
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	echo "Wrong Usage: use it like this ./db.sh {magento_root_dir} {s3_bucket_name} {hourly|daily_m|daily_w|single|monthly}"
	exit
fi


#######################################
#Args Variables
#######################################

#Make sure Mage dir given doesn't has final slash (standard to add it in the script)
MAGENTO_DIR=${1%/}
S3BUCKET=$2
TYPE=$3


#######################################
#Script Initial Settings
#######################################

#Directory where we'll save BU's
BACKUP_DIR=$MAGENTO_DIR"/var/_tempbudb_/"
#Script Base Dir
BASE_DIR="$(dirname "$0")"

#Import common initial functionality
source $BASE_DIR"/_init.sh"


#######################################
#DB Backup Functionality
#######################################

#DB Backup Name
FILENAME=$(get_filename $TYPE $DB_NAME)

#Create DB Dump
echo "MYSQLDUMP DB: $FILENAME.sql"
#TODO: What if this errors
mysqldump --extended-insert=FALSE -u$DB_USER -p$DB_PASS $DB_NAME > $BACKUP_DIR$FILENAME.sql

# tar.gz the dump
echo "TAR DB Dump: $FILENAME.tar.gz"
tar -pczf $BACKUP_DIR$FILENAME.tar.gz -C $BACKUP_DIR $FILENAME.sql


#######################################
#Import common final functionality:
#   Push BU to S3
#   Delete Temp Folder
#######################################

source $BASE_DIR"/_end.sh"
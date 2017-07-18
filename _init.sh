#Scripts common initial functionality:
#   NOTE: THIS IS FOR MAGENTO ONLY
#
#   Imports functions, checks args, gets DB Config, checks & creates s3bucket
#


#Import common functions
source "./_functions.sh"

echo "

------------------------------- Beginning S3 Script -------------------------------

"

#check that magento directory is valid
mage_check_dir $MAGENTO_DIR

#Get DB Config
DB_USER=$(mage_get_config "username" $MAGENTO_DIR)
DB_PASS=$(mage_get_config "password" $MAGENTO_DIR)
DB_NAME=$(mage_get_config "dbname" $MAGENTO_DIR)
DB_PREFIX=$(mage_get_config "table_prefix" $MAGENTO_DIR)

#Set some config options

#Check that bucket exists, create if it doesn't
s3_bucket_exists $S3BUCKET

#Create Backup Dir. TODO: What if this errors
echo "MKDIR temp backup folder: $BACKUP_DIR"
mkdir $BACKUP_DIR


#!/usr/bin/env bash
##############################################################################################################
#HOW TO
#
#Make sure the script has execution permissions
#At shell run:
#sh ./fd_media_backup.sh {magento_root_dir} {s3_bucket_name} {hourly|daily_m|daily_w|single|monthly}
#
#{magento_root_dir} -> The folder which has the folders app/, media/, var/, skin/.
#{s3_bucket_name}   -> The S3 Bucket Name that will be used for the backups. Something like domain.com-mediabackup is always a good name.
#{hourly|daily_m|daily_w|single|monthly}  -> The type of backup file. 
#		If hourly, it will create a file called dbname_hourly_n.tar.gz. Where "n" is the current hour (24 hour format) (1 am is 1, not 01) 
#		If daily_m, it will create a file called dbname_daily_m_nn.tar.gz. Where "nn" is the day of the month
#		If daily_w, it will create a file called dbname_daily_w_n.tar.gz. Where "n" is the day of the week
#		If single, it will create a file called dbname_single.tar.gz
#		If monthly, it will create a file called dbname_monthly_nn.tar.gz. Where "nn" is the current month
#
##############################################################################################################

#######################################
#Script Behavior Configuration
#######################################

#Set this to 1 to not use S3 (condition at s3_FUNCTIONS())
S3_TEST=0
DEL_TEMPDIR=1

#check arguments count and not empty
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	echo "Wrong Usage: use it like this ./media.sh {magento_root_dir} {s3_bucket_name} {hourly|daily_m|daily_w|single|monthly}"
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
BACKUP_DIR=$MAGENTO_DIR"/var/_tempbumedia_/"
#Script Base Dir
BASE_DIR="$(dirname "$0")"

#Import common initial functionality
source $BASE_DIR"/_init.sh"


#######################################
#Media Backup Functionality
#######################################

SUFIX=$(get_filename $TYPE $BACKUP_DIR"media")

MEDIA_CAT_PROD_DIR=$MAGENTO_DIR"/media/catalog/product/"

#save product images
echo "Saving product media"
for i in $MEDIA_CAT_PROD_DIR* ; do
  if [ -d "$i" ]; then
    if [[ "$i" != $MEDIA_CAT_PROD_DIR'cache' ]] && [[ "$i" != $MEDIA_CAT_PROD_DIR'-' ]] && [[ "$i" != $MEDIA_CAT_PROD_DIR'_' ]] ; then
    	FILENAME=$SUFIX"catalog_product_"$(basename "$i").tar.gz
    	echo $MEDIA_CAT_PROD_DIR$(basename "$i")"/ ==> $FILENAME"
	tar -pczf $FILENAME -C "$MAGENTO_DIR/media/" catalog/product/$(basename "$i")
    fi
  fi
done

MEDIA_CAT_DIR=$MAGENTO_DIR"/media/catalog/"
#Save all other media/catalog/* folders (except cache and product)
echo "Saving media/catalog images"
for i in $MEDIA_CAT_DIR* ; do
  if [ -d "$i" ]; then
    if [[ "$i" != $MEDIA_CAT_DIR'cache' ]] && [[ "$i" != $MEDIA_CAT_DIR'product' ]] ; then
    	FILENAME=$SUFIX"catalog_"$(basename "$i").tar.gz
    	echo $MEDIA_CAT_DIR$(basename "$i")"/ ==> $FILENAME"
	tar -pczf $FILENAME -C "$MAGENTO_DIR/media/" catalog/$(basename "$i")
    fi
  fi
done

MEDIA_DIR=$MAGENTO_DIR"/media/"
#Save all other media/ folders (except cache)
echo "Saving all other media images"
for i in $MEDIA_DIR* ; do
  if [ -d "$i" ]; then
    if [[ "$i" != $MEDIA_DIR'cache' ]] && [[ "$i" != $MEDIA_DIR'catalog' ]] ; then
    	FILENAME=$SUFIX$(basename "$i").tar.gz
    	echo $MEDIA_DIR$(basename "$i")"/ ==> $FILENAME"
	tar -pczf $FILENAME -C "$MAGENTO_DIR/media/" $(basename "$i")
    fi
  fi
done


for i in $BACKUP_DIR*.tar.gz ; do
	#check if file is bigger than 5GB (S3 Restriction). Split if it is
	BUSIZE=$(stat -c %s $i)
	if [ $BUSIZE -gt 5000000000 ]; then
		echo "Splitting file $i. Total size: $BUSIZE"
		split -b1000000000 $i $i-
		echo "Removing file $i"
		rm $i;
	fi
done


#copy to s3, forced to overwrite.
echo "COPY to S3 bucket: $S3BUCKET"
s3_save_dircontent $S3BUCKET $BACKUP_DIR

echo "DELETE Temp Backup dir: $BACKUP_DIR"

if [ $DEL_TEMPDIR == 1 ]; then
    echo "DELETE Temp Backup dir: $BACKUP_DIR"
    rm -rf $BACKUP_DIR
fi

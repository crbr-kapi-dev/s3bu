##############################################################################################################
# Common functionality between scripts
##############################################################################################################


#This won't work, has to be done on each file (or figure out how to access script $N vars, instead of function $N vars.
#check_args () {
#    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
#        echo "Wrong Usage: use it like this ./db.sh {magento_root_dir} {s3_bucket_name} {hourly|daily_m|daily_w|single|monthly}"
#        exit
#    fi
#}


mage_check_dir() {
    #check that magento directory is valid
    if [ ! -d "$1" -o ! -d $1"/app/etc" -o ! -f $1"/app/etc/local.xml" ]; then
        echo "The magento directory is not valid. It should be were your media/ and app/ folders are: ($MAGENTO_DIR)"
        exit
    fi
}



mage_get_config() {
    VAL=$(sed -n 's|<'$1'><\!\[CDATA\[\(.*\)\]\]></'$1'>|\1|p' $2/app/etc/local.xml | tr -d ' ')
    echo $VAL
}



#Arg1: Backup Type
#Arg2: Path/Basename ($OUTPUT$DB_NAME)
get_filename() {
    if [ "hourly" == $1 ];  then
        FILENAME=$2"_"$1"_"$(date +%-H)
    elif [ "daily_w" == $1 ]; then
        FILENAME=$2"_"$1"_"$(date +%-u)
    elif [ "daily_m" == $1 ]; then
        FILENAME=$2"_"$1"_"$(date +%-d)
    elif [ "single" == $1 ]; then
        FILENAME=$2"_"$1
    elif [ "monthly" == $1 ]; then
        FILENAME=$2"_"$1"_"$(date +%-m)
    else
        echo "$1 backup type not supported. Valid Options: hourly, daily_m, daily_w, single, monthly."
        exit
    fi

    echo $FILENAME
}


s3_bucket_exists() {
    if [ $S3_TEST == 1 ]; then
        echo "S3 TEST MODE: s3_bucket_exists($1)"
        return
    fi

    #Check that bucket exists, create if it doesn't
    EXISTS=$(s3cmd info s3://$1)

    if [ -z "$EXISTS" ]; then
        echo "Creating bucket $1"
        #TODO: what if this errors?
        s3cmd mb s3://$1
#    else
#        echo "Bucket $1 found"
    fi
}


#Arg1: Bucket
#Arg2: Filename
s3_file_exists() {
    if [ $S3_TEST == 1 ]; then
        echo "S3 TEST MODE: s3_file_exists($1, $2)"
        return
    fi

    #Check if file exists, delete if it does
    EXISTS=$(s3cmd info s3://$1/$(basename $2).tar.gz)

    if [ -z "$EXISTS" ]; then
        echo "File "$(basename $2)" good to go"
    else
        echo "File "$(basename $2)" exists. Deleting..."
        s3_delete_file s3://$1/$(basename $2).tar.gz
    fi

}

#Arg1: Bucket
#Arg2: Filename
s3_save_file() {
    if [ $S3_TEST == 1 ]; then
        echo "S3 TEST MODE: s3_save_file($1, $2)"
        return
    fi

    echo "S3 PUT $2 s3://$1"
    s3cmd put $2 s3://$1
}

#Arg1: Bucket
#Arg2: Folder Pattern
s3_save_dircontent() {
    if [ $S3_TEST == 1 ]; then
        echo "S3 TEST MODE: s3_save_dircontent($1, $2)"
        return
    fi

    echo "S3 PUT (dir) $2 s3://$1"
    s3cmd -r -f put $2 s3://$1
}

s3_delete_file() {
    if [ $S3_TEST == 1 ]; then
        echo "S3 TEST MODE: s3_delete_file($1)"
        return
    fi

    echo "S3 DEL $1"
    s3cmd del $1
}


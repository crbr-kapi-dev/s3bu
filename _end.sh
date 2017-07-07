#Check if file exists, delete if it does
s3_file_exists $S3BUCKET $FILENAME.tar.gz

#copy to s3
s3_save_file $FILENAME.tar.gz $S3BUCKET
echo "S3 PUT to bucket: $S3BUCKET"

if [ $DEL_TEMPDIR == 1 ]; then
    echo "DELETE Temp Backup dir: $OUTPUT"
    rm -rf $OUTPUT
fi

echo "

------------------------------- End S3 Script -------------------------------

"

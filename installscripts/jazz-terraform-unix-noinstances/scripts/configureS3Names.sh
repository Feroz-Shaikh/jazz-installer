#!/bin/bash

jazz_bucket_dev=$1
jazz_bucket_stg=$2
jazz_bucket_prod=$3
jazz_bucket_cloudfrontlogs=$4
jazz_bucket_web=$5
jenkinsjsonpropsfile=$6

sed -i "s/jazz_bucket_dev\".*.$/jazz_bucket_dev\": \"$jazz_bucket_dev\",/g" $jenkinsjsonpropsfile
sed -i "s/jazz_bucket_stg\".*.$/jazz_bucket_stg\": \"$jazz_bucket_stg\",/g" $jenkinsjsonpropsfile
sed -i "s/jazz_bucket_prod\".*.$/jazz_bucket_prod\": \"$jazz_bucket_prod\",/g" $jenkinsjsonpropsfile
sed -i "s/jazz_bucket_cloudfrontlogs\".*.$/jazz_bucket_cloudfrontlogs\": \"$jazz_bucket_cloudfrontlogs\",/g" $jenkinsjsonpropsfile
sed -i "s/jazz_bucket_web\".*.$/jazz_bucket_web\": \"$jazz_bucket_web\"/g" $jenkinsjsonpropsfile

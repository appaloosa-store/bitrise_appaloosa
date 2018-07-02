#!/usr/bin

function getJSONValue {
    cat "$1" | grep "$2" | sed "s/.*\"$2\"[^:]*:[^\"]*\"\([^\"]*\)\".*/\1/"
}

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

content_type=""
date="$(LC_ALL=C date -u +"%a, %d %b %Y %X %z")"
md5="$(openssl md5 -binary < "$bitrise_ipa_path" | base64)"
binary_file_name="$(ruby $THIS_SCRIPT_DIR/file_name_extractor.rb "$bitrise_ipa_path")"
SIG_PATH_GROUP_KEY_CPATH=`curl -H "Content-Type: application/json" -X GET --data '{"store_id":"'"$store_id"'", "md5":"'"$md5"'", "date":"'"$date"'", "group_ids":"'"$group_ids"'", "binary_file_name": '"$binary_file_name"'}' $end_path/$store_id/bitrise_binaries/generate_signature?api_key=$appaloosa_api_key`

echo $SIG_PATH_GROUP_KEY_CPATH > filejson

if [[ $SIG_PATH_GROUP_KEY_CPATH == '' ]];then
    echo 'A problem has occurred, check these params: api_key, store_id, group_ids'
    exit 1
fi

sig=`getJSONValue filejson sign`
GROUP=`getJSONValue filejson groups`
path=`getJSONValue filejson path`
access_key=`getJSONValue filejson access_key`

if [[ -n "$GROUP" ]];then
  echo 'ERROR: Group_ids params is invalid'
  exit 1
fi

curl -T $bitrise_ipa_path $path \
    -H "Date: $date" \
    -H "Authorization: AWS $access_key:$sig" \
    -H "Content-Type: $content_type" \
    -H "Content-MD5: $md5"


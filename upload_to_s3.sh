
function getJSONValue {    
    cat "$1" | grep "$2" | sed "s/.*\"$2\"[^:]*:[^\"]*\"\([^\"]*\)\".*/\1/"
}

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

content_type=""
date="$(LC_ALL=C date -u +"%a, %d %b %Y %X %z")"
md5="$(openssl md5 -binary < "$bitrise_ipa_path" | base64)"
SIG_PATH_GROUP_KEY_CPATH=`curl -H "Content-Type: application/json" -X GET --data '{"store_id":"'"$store_id"'", "md5":"'"$md5"'", "date":"'"$date"'", "group_ids":"'"$GROUP"'" }' $APPALOOSA_SERVER/$store_id/bitrise_binaries/generate_signature?api_key=$appaloosa_api_key`

echo $SIG_PATH_GROUP_KEY_CPATH > filejson

if [[ $SIG_PATH_GROUP_KEY_CPATH == '' ]];then
    echo 'Problem occured, check these params: api_key, store_id, group_ids'
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


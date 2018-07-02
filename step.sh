#!/usr/bin

echo "end path    :  ${end_path}"
echo "binary path :  ${bitrise_ipa_path}"
echo "description :  ${description}"
echo "group ids   :  ${group_ids}"
echo "api key     :  ${appaloosa_api_key}"
echo "store id    :  ${store_id}"
echo "user email  :  ${user_email}"
echo "screenshot1 :  ${screenshot1}"
echo "screenshot2 :  ${screenshot2}"
echo "screenshot3 :  ${screenshot3}"
echo "screenshot4 :  ${screenshot4}"
echo "screenshot5 :  ${screenshot5}"
echo "changelog   :  ${changelog}"

function getJSONValue {
    cat "$1" | grep "$2" | sed "s/.*\"$2\"[^:]*:[^\"]*\"\([^\"]*\)\".*/\1/"
}

# Environment settings
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Error
if [ -z "$user_email" ] && [ -z "$appaloosa_api_key" ]; then
  echo "ERROR: An email address or your API key is required"
  exit 1
fi
# email and API are both provided
if [ -n "$user_email" ] && [ -n "$appaloosa_api_key" ]; then
  echo "WARNING: You provided an email and an API key, we will consider your API key"
# API key is given without store id
fi
if [ -z "$store_id" ] && [ -n "$appaloosa_api_key" ]; then
  echo "ERROR: store id is required"
  exit 1
fi

# With e-mail address
if [[ -z "$appaloosa_api_key" ]] && [[ -n "$user_email" ]];then
  RESP=`curl -H "Content-Type: application/json" -X POST $end_path/upload_services/create_an_account?email=$user_email`

  #email unique?
  echo $RESP > response_account

  ERR=`getJSONValue response_account errors`
  if [[ -n $ERR ]];then
    echo $ERR
    exit 1
  fi

  appaloosa_api_key=`getJSONValue response_account api_key`
  store_id=`getJSONValue response_account store_id`
fi

# upload on S3
source $THIS_SCRIPT_DIR/upload_to_s3.sh
# get ipa_path
S3_IPA_PATH=`curl -H "Content-Type: application/json" -X GET --data '{"store_id":"'"$store_id"'", "key":"'"$path"'"}' $end_path/$store_id/upload_services/url_for_download?api_key=$appaloosa_api_key`
echo $S3_IPA_PATH > path_url

echo $S3_IPA_PATH > s3_path
S3_IPA_PATH=`getJSONValue s3_path binary_url`

# check_path
ERR=`getJSONValue path_url errors`
if [[ -n $ERR ]];then
  echo $ERR
  exit 1
fi

# upload on Appaloosa
UPLOAD=`curl -H "Content-Type: application/json" -X POST --data '{ "application": { "binary_path": "'"$S3_IPA_PATH"'", "description": '"$(ruby $THIS_SCRIPT_DIR/json_dumper.rb "$description")"', "group_ids": "'"$group_ids"'", "screenshot1": "'"$screenshot1"'", "screenshot2": "'"$screenshot2"'", "screenshot3": "'"$screenshot3"'", "screenshot4": "'"$screenshot4"'", "screenshot5": "'"$screenshot5"'", "changelog": '"$(ruby $THIS_SCRIPT_DIR/json_dumper.rb "$changelog")"'}, "provider": "bitrise"}' $end_path/$store_id/applications/upload?api_key=$appaloosa_api_key`

echo $UPLOAD
echo $UPLOAD > upload
ERR=`getJSONValue upload errors`
if [[ -n $ERR ]];then
  echo $ERR
  exit 1
fi

unset appaloosa_api_key
unset store_id

exit $?

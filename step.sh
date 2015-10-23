echo "BINARY PATH :  ${BITRISE_IPA_PATH}"
echo "DESCRIPTION :  ${DESCRIPTION}"
echo "GROUP IDS   :  ${GROUP_IDS}"
echo "API KEY     :  ${APPALOOSA_API_KEY}"
echo "STORE ID    :  ${STORE_ID}"
echo "USER EMAIL  :  ${USER_EMAIL}"
echo "SCREENSHOT1 :  ${SCREENSHOT1}"
echo "SCREENSHOT2 :  ${SCREENSHOT2}"
echo "SCREENSHOT3 :  ${SCREENSHOT3}"
echo "SCREENSHOT4 :  ${SCREENSHOT4}"
echo "SCREENSHOT5 :  ${SCREENSHOT5}"

function getJSONValue {    
    cat "$1" | grep "$2" | sed "s/.*\"$2\"[^:]*:[^\"]*\"\([^\"]*\)\".*/\1/"
}

# Environment settings
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

APPALOOSA_SERVER="https://www.appaloosa-store.com/api/v1"

# Error
if [ -z "$USER_EMAIL" ] && [ -z "$APPALOOSA_API_KEY" ]; then
  echo "ERROR: An email address or your API key are required"
  exit 1
fi
# email and API are both provided
if [ -n "$USER_EMAIL" ] && [ -n "$APPALOOSA_API_KEY" ]; then
  echo "WARNING: You provided an email and an API key, we will consider your API key"
# API key is given without store id
fi
if [ -z "$STORE_ID" ] && [ -n "$APPALOOSA_API_KEY" ]; then
  echo "ERROR: store id is required"
  exit 1
fi

# copy binary to generic file
cp $BITRISE_IPA_PATH .
mv /Users/vagrant/git/*.ipa binary.ipa
binary="binary.ipa"

# With e-mail address
if [[ -z "$APPALOOSA_API_KEY" ]] && [[ -n "$USER_EMAIL" ]];then
  RESP=`curl -H "Content-Type: application/json" -X POST $APPALOOSA_SERVER/bitrise_binaries/create_an_account?email=$USER_EMAIL`

  #email unique?
  echo $RESP > response_account

  ERR=`getJSONValue response_account errors`
  if [[ -n $ERR ]];then
    echo $ERR
    exit 1
  fi
  APPALOOSA_API_KEY=`getJSONValue response_account api_key`
  STORE_ID=`getJSONValue response_account store_id`
fi

# upload on S3
source $THIS_SCRIPT_DIR/upload_to_s3.sh
# get ipa_path
S3_IPA_PATH=`curl -H "Content-Type: application/json" -X GET --data '{"store_id":"'"$STORE_ID"'", "key":"'"$path"'"}' $APPALOOSA_SERVER/$STORE_ID/bitrise_binaries/url_for_download?api_key=$APPALOOSA_API_KEY`
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
UPLOAD=`curl -H "Content-Type: application/json" -X POST --data '{ "application": { "binary_path": "'"$S3_IPA_PATH"'", "description": "'"$DESCRIPTION"'", "group_ids": "'"$GROUP_IDS"'", "screenshot1": "'"$SCREENSHOT1"'", "screenshot2": "'"$SCREENSHOT2"'", "screenshot3": "'"$SCREENSHOT3"'", "screenshot4": "'"$SCREENSHOT4"'", "screenshot5": "'"$SCREENSHOT5"'"}}' $APPALOOSA_SERVER/$STORE_ID/applications/upload?api_key=$APPALOOSA_API_KEY`

echo $UPLOAD > upload
ERR=`getJSONValue upload errors`
if [[ -n $ERR ]];then
  echo $ERR
  exit 1
fi

unset APPALOOSA_API_KEY
unset STORE_ID

exit $?
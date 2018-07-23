#!/bin/bash
bold=$(tput bold)
normal=$(tput sgr0)

if [[ $# -ne 2 ]]; then
   echo "Usage:"
   echo "purge_history <retention days> <api tokent file name>"
   exit 1
fi

if [[ -f "$2" ]]; then
   TOKEN=`cat $2`
else
   echo "Can not locate $2"
   exit 1
fi

RETENTION=$1
NODE=dsvl1402.ad.verinthms.com

echo "Executing purge_job_history for project ${PROJECT} retention ${RETENTION}"
date

CURL_OUT=/tmp/curl.out.$$
CURL_LIST=/tmp/listproject.xml

URL="http://${NODE}:4440/api/2/projects"
curl -H "X-RunDeck-Auth-Token:$TOKEN" "Content-Type: application/xml"  -X GET "$URL"  2>/dev/null  > $CURL_LIST

projects=`xmlstarlet sel -t -m "/result/projects/project" -v name -n $CURL_LIST`

purged=0
for PROJECT in $projects
do
   echo -e "\n${bold}${PROJECT}${normal}"
   #Listing of execution older then ${RETENTION}
   URL="http://${NODE}:4440/api/20/project/${PROJECT}/executions?olderFilter=${RETENTION}&&max=3000"
   curl -H "X-RunDeck-Auth-Token:$TOKEN" "Content-Type: application/xml" -X GET "$URL" >/dev/null  2>&1 > ${CURL_OUT}

  for ID in $(xmlstarlet sel -t -m "/executions/execution" -m "@id" -v . -n ${CURL_OUT})
  do
    #Removing process based on id
    URL="http://${NODE}:4440/api/20/executions/delete?ids=${ID}"

    echo "#################################################################"
    echo "Deleted job $URL"

    #echo curl -H "X-RunDeck-Auth-Token:$TOKEN"  -X POST "$URL"  2>&1

    curl -H "X-RunDeck-Auth-Token:$TOKEN"  -X POST "$URL"  2>&1

    purged=$((purged+1))
  done
done

echo -e "\n${bold}Finish Purge History older than ${RETENTION}"
echo "Job executions purged:  $purged${normal}"


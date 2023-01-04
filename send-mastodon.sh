#!/bin/bash
shopt -s nocasematch
set -e

# put in your token
TOKEN="XXX"
# put in your domain
DOMAIN="botsin.space"

# generate a unique key (not supposed to be secure.. just unique in an hour)
KEY="$$`date +%s`"
KEY=`echo ${KEY} | md5sum | cut -f1 -d" "`

# see what app is talking to us, and format the message
if [ ! -z ${sonarr_eventtype+x} ];
then
        case ${sonarr_eventtype} in
        Test)
                LOGMESSAGE="[sonarr] Test message. If you're seeing this on your mastodon account you have configured things correctly!"
                ;;
        Download)
                LOGMESSAGE="[sonarr] Imported: ${sonarr_series_title} - ${sonarr_episodefile_seasonnumber}x${sonarr_episodefile_episodenumbers} - ${sonarr_episodefile_episodetitles} [${sonarr_episodefile_quality}]"
                ;;
        esac
elif [ ! -z ${radarr_eventtype+x} ];
then
        case ${radarr_eventtype} in
        Test)
                LOGMESSAGE="[radarr] Test message. If you're seeing this on your mastodon account you have configured things correctly!"
                ;;
        Download)
                LOGMESSAGE="[radarr] Imported: ${radarr_movie_title} (${radarr_movie_year}) [${radarr_moviefile_quality}]"
                ;;
        esac
elif [ ! -z ${lidarr_eventtype+x} ];
then
        case ${lidarr_eventtype} in
        Test)
                LOGMESSAGE="[lidarr] Test message. If you're seeing this on your mastodon account you have configured things correctly!"
                ;;
        AlbumDownload)
                LOGMESSAGE="[lidarr] Imported: ${lidarr_artist_name} - ${lidarr_album_title} "
                ;;
        TrackRetag)
                LOGMESSAGE="[lidarr] Tagged: ${lidarr_artist_name} - ${lidarr_album_title} - ${lidarr_trackfile_tracknumbers} - ${lidarr_trackfile_tracktitles} [${lidarr_trackfile_quality}]"
                ;;
        esac
elif [ ! -z ${readarr_eventtype+x} ];
then
        case ${readarr_eventtype} in
        Test)
                LOGMESSAGE="[readarr] Test message. If you're seeing this on your mastodon account you have configured things correctly!"
                ;;
        Download)
                LOGMESSAGE="[readarr] Imported: ${readarr_author_name} - ${readarr_book_title} (${readarr_book_releasedate})"
                ;;
        esac
else
        exit 1;
fi

if [ ! -n ${LOGMESSAGE} ]
then
        exit 2;
fi

# escape and format the message into json
LOGMESSAGE=`echo ${LOGMESSAGE} | sed 's/\\\\/\\\\\\\\/g'`
LOGMESSAGE=`echo ${LOGMESSAGE} | sed 's/"/\\\\"/g'`
LOGMESSAGE='{"status": "'${LOGMESSAGE}'"}'

# dump values to file. Helps deal with shell escaping
FILE=`mktemp -p /tmp/`
echo ${LOGMESSAGE} > ${FILE}

# make the request
/usr/bin/curl --silent https://${DOMAIN}/api/v1/statuses -H "Idempotency-Key: ${KEY}" -H "Authorization: Bearer ${TOKEN}" -H 'Content-Type: application/json' -d @${FILE}

# clean up the file
rm -f ${FILE}
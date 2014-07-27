#!/bin/bash

#################################################
#				Common Functions				#
#												#
#		Author : Yanjun							#
#		Date   : 2014-07-22						#
#		Version: 1.0							#
#################################################

export LANG="en_US.UTF-8"

. ./config.sh


#=========================================================
# NAME       : send_email
# DESCRIPTION: Send email alert when exceptions occurred.
# PARAMETER 1: email content
#=========================================================
function send_email() {
	m=$1
	echo `date +"%Y-%m-%d %H:%M:%S"`" Send email to alert the exceptions..."
	$SEND_MAIL -f "$f" -t "$t" -u "$u" -m "$m" -s "$s"  -xu "$xu" -xp "$xp"
	if [ "$?" -eq 0 ]; then
		echo `date +"%Y-%m-%d %H:%M:%S"`" Send email successfully!"
	else
		echo `date +"%Y-%m-%d %H:%M:%S"`" Fail to send email, please check it!"
	fi
}
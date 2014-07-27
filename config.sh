#!/bin/bash

#################################################
#		Sync Environment Configuration			#
#												#
#		Author     : Yanjun						#
#		Date       : 2014-07-22					#
#		Version    : 1.0						#
#		Description: Configurations for remote  #
#					 peer, local and tools.		#
#################################################

export LANG="en_US.UTF-8"

# Remote peer configuration
REMOTE_HOST='10.10.4.126'
REMOTE_USER='hadoop'
REMOTE_DIR='/home/hadoop/logs'

# Local configuration
LOCAL_DIR='/home/hadoop/logs'
TX_FILE=$REMOTE_HOST".tx"
LOCK_FILE=$REMOTE_HOST".lock"
LOG_FILE_SUFFIX='.log'
TMP_FILE_SUFFIX='.tmp'
DEFAULT_MINUTES_AGO=1
DEFAULT_MINUTES_COUNT=1

# Log level
INFO=' [INF]'
WARN=' [WRN]'
ERROR=' [ERR]'
FATAL=' [FAL]'

########################################################################
# Email configuration
#
# INSTALL sendEmail tool:
# 1. Switch super user account
# 2. wget http://caspian.dotconf.net/menu/Software/SendEmail/sendEmail-v1.56.tar.gz
# 3. tar xvzf sendEmail-v1.56.tar.gz
# 4. ln -s /usr/local/sendEmail-v1.56 /usr/local/sendEmail
#######################################################################
SEND_MAIL='/usr/local/bin/sendEmail'
f="Minutely Sync Alert<from@from.mail.domain>"
t="recv1@to.mail.domain recv2@to.mail.domain" 
u="[Sync alert: "`date +"%Y-%m-%d %H:%M:%S"`"]"
s="smtp.from.mail.domain"
xu="user"
xp="passwprd"

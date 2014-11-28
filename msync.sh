#!/bin/bash

#################################################
#		Copy Log Files from Remote Host			#
#												#
#		Author : Yanjun							#
#		Date   : 2014-07-22						#
#		Version: 1.0							#
#################################################

export LANG="en_US.UTF-8"
CUR=`pwd`
echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Current workspace: cur=$CUR"

# Initialize environment variables and common functions
. ./config.sh
. ./commons.sh

SWITCH=''
MINUTES_AGO=$DEFAULT_MINUTES_AGO
MINUTES_COUNT=$DEFAULT_MINUTES_COUNT

TOTAL_COUNT=0
SUCCESS_COUNT=0
FAILURE_COUNT=0

ARGC=$#
ARGV=$@

#=========================================================
# NAME       : print_usage
# DESCRIPTION: Print script usage information.
#=========================================================
function print_usage() {
	echo `date +"%Y-%m-%d %H:%M:%S"`"$ERROR Error to input arguments: argc=$ARGC, argv=$ARGV"
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO ################################# Usage for script #############################"
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO # $0  <switch> [<minutes_ago> [<minutes_count>]]                                "
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO # 	  Options:                                                                 "
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO #          switch       : Required. a - sync automatically; m - sync manually.  "
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO #          minutes_ago  : Optional. default $DEFAULT_MINUTES_AGO.                "
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO #          minutes_count: Optional. default $DEFAULT_MINUTES_COUNT.             "
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO ###################################################EE###########################"
	exit 1
}

# Parse arguments, and set variables' value
if [ "$ARGC" -eq 0 ]; then
	print_usage
elif [ "$ARGC" -eq 1 ]; then
	SWITCH=$1
elif [ "$ARGC" -eq 2 ]; then
	SWITCH=$1
	MINUTES_AGO=$2
elif [ "$ARGC" -eq 3 ]; then
	SWITCH=$1
	MINUTES_AGO=$2
	MINUTES_COUNT=$3
else
	print_usage
fi

echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO #########################################"
echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO # Initialized parameter values: 			"
echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO # 										"
echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO # SWITCH        = $SWITCH				"
echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO # MINUTES_AGO   = $MINUTES_AGO			"
echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO # MINUTES_COUNT = $MINUTES_COUNT			"
echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO #########################################"


function incr_total() {
	TOTAL_COUNT=$((TOTAL_COUNT+1))
}

function incr_success() {
	SUCCESS_COUNT=$((SUCCESS_COUNT+1))
}

function incr_failure() {
	FAILURE_COUNT=$((FAILURE_COUNT+1))
}

function lock() {
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Try to lock..."
	touch $LOCK_FILE
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Locked!"
}

function unlock() {
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Try to unlock..."
	rm $LOCK_FILE
	if [ "$?" -eq 0 ]; then
		echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Unlocked!"
	else
		echo `date +"%Y-%m-%d %H:%M:%S"`"$FATAL Fail to unlock!"
		send_email "Sync workspace was locked, please check! Solve the problem, plz delete lock files`pwd`/*.lock manually!!! "
	fi
}

#=========================================================
# NAME       : check
# DESCRIPTION: Check directories, lock files and TX files.
# PARAMETER 1: local directory
# PARAMETER 2: TX file name
# PARAMETER 3: lock file name
#=========================================================
function check() {
	local_dir=$1
	tx_file=$2
	lock_file=$3
	# check local directory
	if [ ! -e $local_dir ]; then
		echo `date +"%Y-%m-%d %H:%M:%S"`"$ERROR Directory does not exist: $local_dir!"
		exit 1	
	fi
	# check lock file
	if [ -e $lock_file ]; then
		echo `date +"%Y-%m-%d %H:%M:%S"`"$ERROR Sync is locked!"
		exit 1
	else
		# lock the workspace
		lock
	fi
	
	# check TX file and prepare
	if [ ! -e $tx_file ]; then
		touch $tx_file
		echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Touch file: $tx_file"
	fi
}

#=========================================================
# NAME       : copy_file
# DESCRIPTION: Copy a file from remote peer to local.
# PARAMETER 1: local directory
# PARAMETER 2: remote link
# PARAMETER 3: remote directory
# PARAMETER 4: file name
# PARAMETER 5: TX file name
#=========================================================
function copy_file() {
	# increment total counter
	incr_total
	local_dir=$1
	remote_link=$2
	remote_dir=$3
	pending_file=$4
	tx_file=$5
	remote_file=$remote_link':'$remote_dir'/'$pending_file
	local_file=$local_dir'/'$pending_file
	tmp_file=$local_file"$TMP_FILE_SUFFIX"
	# check TX file
	result=`grep $pending_file $tx_file`
	if [ -z $result ]; then
		scp $remote_file $tmp_file
		if [ "$?" -eq 0 ]; then
			# increment success counter
			incr_success
			# sleep 5s # used for debugging
			mv $tmp_file $local_file
			echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Synced: remote=$remote_file, local=$local_file"
			# TODO check whether $file TX existed in $tx_file
			if [ -z "$pending_file" ]; then
				echo `date +"%Y-%m-%d %H:%M:%S"`"$FATAL Will record empty TX line!!!"
				exit 1
			fi
			
			echo $pending_file >> $tx_file
		else
			# increment failure counter
			incr_failure
			echo `date +"%Y-%m-%d %H:%M:%S"`"$WARN Fail to sync: remote=$remote_file, local=$local_file"
		fi
	else
		# increment failure counter
		incr_failure
		echo `date +"%Y-%m-%d %H:%M:%S"`"$WARN Already committed: remote=$remote_file, local=$local_file"
	fi
}

#=========================================================
# NAME       : copy_files
# DESCRIPTION: Copy files from remote peer to local.
# PARAMETER 1: local directory
# PARAMETER 2: remote link
# PARAMETER 3: remote directory
# PARAMETER 4: log file name suffix
# PARAMETER 5: TX file name
# PARAMETER 6: minutes ago
# PARAMETER 7: minutes count
#=========================================================
function copy_files() {
	local_dir=$1
	remote_link=$2
	remote_dir=$3
	log_file_suffix=$4
	tx_file=$5
	minutes_ago=$6
	minutes_count=$7
	minutes_limit=$((minutes_ago+minutes_count))
	for((i=$minutes_limit;i>=$minutes_ago;i--)); do
		file=`date +"%Y-%m-%d-%H-%M" -d "$i mins ago"`$log_file_suffix
		# invoke function 'copy_file'
		copy_file $local_dir $remote_link $remote_dir $file $tx_file
	done
}

#=========================================================
# NAME       : auto_copy
# DESCRIPTION: Copy files from remote peer to local automatically.
# PARAMETER 1: local directory for storing synced files
# PARAMETER 2: remote link
# PARAMETER 3: remote directory
# PARAMETER 4: log file name suffix
# PARAMETER 5: TX file name
# PARAMETER 6: lock file name
# PARAMETER 7: minutes ago
# PARAMETER 8: minutes count
#=========================================================
function auto_copy() {
	local_dir=$1
	remote_link=$2
	remote_dir=$3
	log_file_suffix=$4
	tx_file=$5
	lock_file=$6
	minutes_ago=$7
	minutes_count=$8
	
	# invoke function 'check' to check procedure
	check $local_dir $tx_file $lock_file
	
	# last transaction ID in TX file
	last_tx=`tail -1 $tx_file`
	file_name=`date +"%Y-%m-%d-%H-%M" -d "$minutes_ago mins ago"`$log_file_suffix
	if [ -z $last_tx ]; then
		# first time sync log files
		echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO First time to copy file from remote peer: $remote_link"
		# invoke function 'copy_files'
		copy_files $local_dir $remote_link $remote_dir $log_file_suffix $tx_file $minutes_ago $minutes_count
	else
		# sync log files based on existed TX file
		if [ $last_tx == $file_name ]; then
			echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Already synced: $file_name"
			exit 0
		else
			echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Need to copy: last_tx=$last_tx, minutes_ago_file=$file_name"
			i=$minutes_ago
			current=$file_name
			while [[ 1 ]]; do
				if [ "$current" != "$last_tx" ]; then
					current=`date +"%Y-%m-%d-%H-%M" -d "$i mins ago"`$log_file_suffix
					# invoke function 'copy_file'
					copy_file $local_dir $remote_link $remote_dir $current $tx_file
				else
					echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Finished to copy, break..."
					break
				fi
				i=$((i+1))
			done
			echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Done."
		fi
	fi
}

function statis() {
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO #########################################"
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO # Sync result statistics information:	"
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO # 										"
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO # TOTAL_COUNT   = $TOTAL_COUNT			"
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO # SUCCESS_COUNT = $SUCCESS_COUNT			"
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO # FAILURE_COUNT = $FAILURE_COUNT			"
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO #########################################"
}

#=========================================================
# NAME       : main
# DESCRIPTION: Entrance of execution.
#=========================================================
function main() {
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Input arguments: argc=$ARGC, argv=$ARGV"
	remote_link=$REMOTE_USER'@'$REMOTE_HOST
	echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Remote link: $remote_link"
	case "$SWITCH" in 
		'a'|'A')
			# invoke function 'auto_copy' to copy log files automatically
			auto_copy $LOCAL_DIR $remote_link $REMOTE_DIR $LOG_FILE_SUFFIX $TX_FILE $LOCK_FILE $MINUTES_AGO $MINUTES_COUNT
		;;
		'm'|'M')
			# check
			check $LOCAL_DIR $TX_FILE $LOCK_FILE
			# copy log files based on manual operation
			echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO #########################################"
			echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Copy log files from remote peer MANUALLY..."
			# invoke function 'copy_files'
			copy_files $LOCAL_DIR $remote_link $REMOTE_DIR $LOG_FILE_SUFFIX $TX_FILE $MINUTES_AGO $MINUTES_COUNT
			echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO Done."
			echo `date +"%Y-%m-%d %H:%M:%S"`"$INFO #########################################"
		;;
		*)
			print_usage
		;;
	esac
	
	# output statistics information
	statis
	# unlock
	unlock
}

main

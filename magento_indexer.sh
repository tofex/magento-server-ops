#!/bin/bash

host="172.16.1.183"
port="3306"
MY_USER="magento"
MY_PASS="5Nkg7ju){;!u>Ug6{}_P|9kNo8n{47na"
MY_DB="magento"

#echo ""
#echo "$(date +%d-%m-%Y" "%H:%M:%S) run magento indexer"
export MYSQL_PWD="${MY_PASS}"

INDEXER_LIST_ENTITY="catalog_product_index_price_cl cataloginventory_stock_status_cl catalog_product_flat_cl catalog_category_flat_cl enterprise_url_rewrite_product_cl enterprise_url_rewrite_category_cl enterprise_url_rewrite_redirect_cl catalog_category_product_index_cl catalogsearch_fulltext_cl"

MAX_PENDING_EVENTS=100
FULLINDEX=0

LOCKFILE="/tmp/magento-indexerlock"
# lock dirs/files
LOCKDIR="/tmp/magento-indexer-cron"
PIDFILE="${LOCKDIR}/PID"

# exit codes and text
ENO_SUCCESS=0; ETXT[0]="ENO_SUCCESS"
ENO_GENERAL=1; ETXT[1]="ENO_GENERAL"
ENO_LOCKFAIL=2; ETXT[2]="ENO_LOCKFAIL"
ENO_RECVSIG=3; ETXT[3]="ENO_RECVSIG"

#Prüfe ob Teil index Job läuft
IDENTIFIER=09ee80020206fdb20fb06b4d228d3892
LOCKDIR_PARTINDEX="/tmp/magento.aoe_scheduler.${IDENTIFIER}.lock"
PIDFILE_PARTINDEX="${LOCKDIR_PARTINDEX}/PID"

if [ ! -f "${PIDFILE_PARTINDEX}" ]; then
	#echo "no PID File found"
	u=1
else
	OTHERPID_PARTINDEX="$(cat "${PIDFILE_PARTINDEX}")"
	if [ $? != 0 ]; then
		echo "lock failed,another instance is probably about to remove the lock, PID ${OTHERPID_PARTINDEX} is active" >&2
		#return 
		exit 1;
	fi

	# check is the other process is still alive
	ACTIVE=$(ps -fp ${OTHERPID_PARTINDEX} | grep ${OTHERPID_PARTINDEX} | wc -l)
	if [ ${ACTIVE} = "1" ]; then
		echo "$(date +%d-%m-%Y" "%H:%M:%S) Partial Indexing is running with PID: ${OTHERPID_PARTINDEX}"
		exit 1;
	fi
fi


### start locking attempt
trap 'ECODE=$?; echo "$(date +%d-%m-%Y" "%H:%M:%S) [magento-indexer-cron] Exit: ${ETXT[ECODE]}($ECODE)" >&2' 0
##echo "$(date +%d-%m-%Y" "%H:%M:%S) [magento-indexer-cron] try to lock: " >&2
 
if mkdir "${LOCKDIR}" &>/dev/null; then
 
    # lock succeeded, install signal handlers before storing the PID just in case 
    # storing the PID fails
    trap 'ECODE=$?;
          #echo "$(date +%d-%m-%Y" "%H:%M:%S) [magento-indexer-cron] Removing lock. Exit: ${ETXT[ECODE]}($ECODE)" >&2
          rm -rf "${LOCKDIR}"' 0
    echo "$$" >"${PIDFILE}" 
    # the following handler will exit the script upon receiving these signals
    # the trap on "0" (EXIT) from above will be triggered by this trap's "exit" command!
    trap 'echo "$(date +%d-%m-%Y" "%H:%M:%S) [magento-indexer-cron] Killed by a signal." >&2
          exit ${ENO_RECVSIG}' 1 2 3 15
    ##echo "$(date +%d-%m-%Y" "%H:%M:%S) success, installed signal handlers"
 
else
 
    # lock failed, check if the other PID is alive
    OTHERPID="$(cat "${PIDFILE}")"
 
    # if cat isn't able to read the file, another instance is probably
    # about to remove the lock -- exit, we're *still* locked
    #  Thanks to Grzegorz Wierzowiecki for pointing out this race condition on
    #  http://wiki.grzegorz.wierzowiecki.pl/code:mutex-in-bash
    if [ $? != 0 ]; then
      echo "$(date +%d-%m-%Y" "%H:%M:%S) lock failed, PID ${OTHERPID} is active" >&2
      exit ${ENO_LOCKFAIL}
    fi
 
    if ! kill -0 $OTHERPID &>/dev/null; then
        # lock is stale, remove it and restart
        echo "$(date +%d-%m-%Y" "%H:%M:%S) removing stale lock of nonexistant PID ${OTHERPID}" >&2
        rm -rf "${LOCKDIR}"
        echo "$(date +%d-%m-%Y" "%H:%M:%S) [magento-indexer-cron] restarting myself" >&2
        exec "$0" "$@"
    else
        # lock is valid and OTHERPID is active - exit, we're locked!
        echo "$(date +%d-%m-%Y" "%H:%M:%S) Full Indexing is running with PID: ${OTHERPID}" >&2
        exit ${ENO_LOCKFAIL}
    fi
 
fi

#exit 0;
#set own lock
#if [ ! -f "${LOCKFILE}" ]; then
#        touch ${LOCKFILE}
#else
#	echo "$(date +%d-%m-%Y" "%H:%M:%S) Full Indexing is running"
#        exit 1;
#fi


for INDEXER in $INDEXER_LIST_ENTITY
do
        KEY_COLUMN=$(mysql -NB -h"${host}" -u"${MY_USER}" $MY_DB -e "SELECT emm.key_column FROM enterprise_mview_metadata emm WHERE emm.changelog_name='${INDEXER}'")
        CNT=$(mysql -NB -h"${host}" -u"${MY_USER}" $MY_DB -e "SELECT COUNT(DISTINCT(cssc.${KEY_COLUMN})) FROM ${INDEXER} cssc JOIN enterprise_mview_metadata emm ON emm.changelog_name='${INDEXER}' WHERE cssc.version_id > emm.version_id")
 	#echo "${CNT} ${INDEXER}"
	if [ "$CNT" -gt "$MAX_PENDING_EVENTS" ]; then
		#echo "startvollIndex"
		echo "$(date +%d-%m-%Y" "%H:%M:%S) Found for ${CNT} ${INDEXER}"
		INDEXER_CODE=$(mysql -NB -h"${host}" -u"${MY_USER}" $MY_DB -e "SELECT emmg.group_code FROM enterprise_mview_metadata emm JOIN enterprise_mview_metadata_group emmg ON emm.group_id=emmg.group_id AND emm.changelog_name='${INDEXER}' ")
		echo "$(date +%d-%m-%Y" "%H:%M:%S) cd /var/www/villeroyboch/shop; php shell/indexer.php --reindex ${INDEXER_CODE}"
		cd /var/www/villeroyboch/shop; php shell/indexer.php --reindex ${INDEXER_CODE}
		FULLINDEX=$((FULLINDEX + 1))
	fi
done


if [ "$FULLINDEX" -lt 1 ]; then
	/bin/bash /var/www/villeroyboch/shop/scheduler_cron.sh --mode always
fi

#remove own lock
#rm -rf ${LOCKFILE}


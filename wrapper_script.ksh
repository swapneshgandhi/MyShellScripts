#!/bin/ksh
################################################################################
# Program     : basel_hsbc_card_init_cln.ksh
# Description : This wrapper is to run the jobs for init to clean process
# Parameters  : 2 - Required Parameters.feed name
# exit status : 0 - script /graph completed successfully
#               1 - Graph failed
#               2 - Input file not found
#               3 - Matching PSET for the pattern not found
#               4 - JTNM lookup for control M job failed
#               5 - Incorrect number of parameters provided
#
# Date        Author                Project#  Modification
# ==========  ====================  ========  ==================================
# 02/21/2013  CTS                    50887      Created
################################################################################

#############################################################
## INVOKE PROJECT SPECIFIC EME PARAMETERS
##############################################################

DIR=$(dirname $0)

if [[ $0 = '-ksh' || $DIR = '.' ]];then DIR=${PWD};fi
export PROJECT_DIR=$(dirname $DIR)
. $PROJECT_DIR/ab_project_setup.ksh $PROJECT_DIR
. ${ENTPUB_BIN}/dde_coop_version.ksh

 export PATH=${EDWLIB_HOME}/bin:${PATH}
. edwlib.func


JOB_START_DTIM=$(date "+%Y%m%d%H%M%S")
export HOSTNAME=`uname -n`
export Num_Parms=1
export FILE_NAME=$1
export Job_Name=$(basename $0)
export Job_Name_Without_Ext=`echo $Job_Name | awk -F "." '{print $1 }'`
export Dir_Name=$(dirname $0)
export Start_Time=$(date)
arch_flag=0


##############################################################
# TEST NUMBER OF PARAMETERS
##############################################################

LOGFILE=${AI_SERIAL_LOG}/${Job_Name_Without_Ext}_${FILE_NAME}_${JOB_START_DTIM}.log
ERRFILE=${AI_SERIAL_REJECT}/${Job_Name_Without_Ext}_${FILE_NAME}_${JOB_START_DTIM}.rej

1>>${AI_SERIAL_LOG}/${Job_Name_Without_Ext}_${FILE_NAME}_${JOB_START_DTIM}.log
2>>${AI_SERIAL_REJECT}/${Job_Name_Without_Ext}_${FILE_NAME}_${JOB_START_DTIM}.rej


echo "START ${Job_Name}:  ${Start_Time}." >> ${LOGFILE}

if (( $# != ${Num_Parms} )); then
   echo "ERROR: Incorrect number of parameters.Correct usage is ${Job_Name_Without_Ext} <<FEED NAME>> " >> ${LOGFILE}
   echo " Example:  $0 equifax " >> ${LOGFILE}
   echo "Exiting with error code 5." >> ${LOGFILE}
   exit 5
fi

###############################################################################
## Extract the ODATE from .trg File
###############################################################################

      if [[ -f `ls -rt ${AI_SERIAL_TEMP}/*basel_hsbc_${FILE_NAME}init.dat.trg | tail -1` ]] 2>/dev/null
        then
          echo "Trigger File Found." >> ${LOGFILE}
          TRG_FILE=$(basename $(ls -1tr ${AI_SERIAL_TEMP}/*basel_hsbc_${FILE_NAME}_init.dat.trg | tail -1))
          echo "The Trigger file being processed is ${TRG_FILE}">> ${LOGFILE}
      else
          echo "Trigger file  not found in AI_SERIAL_TEMP." >> ${LOGFILE}
          echo "${TRG_FILE} - Trigger file not found. Exiting script" >> ${LOGFILE}
          exit 2
      fi


export ODATE=`echo ${TRG_FILE} | awk -F "_" '{print $1}'`


###############################################################################
## Run the corresponding PSET
###############################################################################


if [[ -f `ls -rt ${AI_PSET}/m_basel_hsbc_${FILE_NAME}_init_to_cln.pset` ]] 2>/dev/null 1>/dev/null
  then
     export JOB_NAME=$(basename $(ls -1tr ${AI_PSET}/m_basel_hsbc_${FILE_NAME}_init_to_cln.pset)) 2>/dev/null
  else
    echo " PSET corresponding to the pattern provided does not exist. Please verify the pattern" >> ${LOGFILE}
    exit 3
 fi



###########################################################################
# Check if Init file is present and extract the name
###########################################################################

      if [[ -f `ls -rt ${AI_SERIAL_TEMP}/${ODATE}_*_basel_hsbc_${FILE_NAME}_init.dat | tail -1` ]] 2>/dev/null
        then
          echo "Init file found." >> ${LOGFILE}
          SORCE_FILE=$(basename $(ls -1tr ${AI_SERIAL_TEMP}/${ODATE}_*_basel_hsbc_${FILE_NAME}_init.dat | tail -1))
          echo "The file being processed is ${SORCE_FILE}">> ${LOGFILE}
      else
          echo "Init File not found in AI_SERIAL_TEMP. Checking in AI_SERIAL_ARCH" >> ${LOGFILE}
        
      fi


GRAPH_PARAMETERS="-SRC_FILE ${AI_SERIAL_TEMP}/${SORCE_FILE} -CURR_DATA_DT ${ODATE}"


################################################################################
#Check the presence of zipped file in archive directory
################################################################################

if [[ ${flag} -eq 1 ]]
  then

      if [[ -f `ls -rt ${AI_SERIAL_ARCH}/${ODATE}_*_basel_hsbc_${FILE_NAME}_init.dat.gz | tail -1` ]] 2>/dev/null
        then
            echo "Zipped file found in archive path."
            SORCE_FILE_ZIP=$(basename $(ls -1tr ${AI_SERIAL_ARCH}/${ODATE}_*_basel_hsbc_${FILE_NAME}_init.dat.gz | tail -1))
            SORCE_FILE=`echo ${SORCE_FILE_ZIP} | awk -F"." '{print $1"."$2}'`
            echo " The file being processed is ${SORCE_FILE_ZIP} " >> ${LOGFILE}
      else
            echo "Zipped file not present in archive directory as well.." >> ${LOGFILE}
            echo "Source file for feed ${FILE_NAME} and date ${ODATE} not found. Exiting script" >> ${LOGFILE}
            exit 2
      fi
fi



###############################################################################
##Check for rec file
###############################################################################


cd ${AI_SERIAL_TEMP}

if [[ -f `ls -rt ${AI_SERIAL_TEMP}/*_basel_hsbc_init_to_cln_*${FILE_NAME}*.rec | tail -1` ]] 2>/dev/null
 then
  echo "Recovery file for job found. Rolling back job..." >> ${LOGFILE}
  REC_FILE=$(basename $(ls -1tr ${AI_SERIAL_TEMP}/*_basel_hsbc_init_to_cln_*${FILE_NAME}*.rec | tail -1))
  m_rollback -d ${REC_FILE} >>${LOGFILE} 1>>/dev/null 2>>/dev/null
  echo "Starting Job after rollback.." >> ${LOGFILE}
  air sandbox run ${AI_PSET}/${JOB_NAME} -reposit-tracking ${GRAPH_PARAMETERS}
else
  air sandbox run ${AI_PSET}/${JOB_NAME} -reposit-tracking ${GRAPH_PARAMETERS}
  #export stat=$?
fi


##Remove the trigger file

rm -f ${AI_SERIAL_TEMP}/$ODATE}_*_${FILE_NAME}*.trg 1>/dev/null 2>/dev/null

##Cleanup old log, reject etc files



    echo "Deleting Old Reject, Error, Summary, Log and zip files older than 150 days" >> ${LOGFILE}

    find ${AI_SERIAL_LOG} -name "*${FILE_NAME}*.log" -mtime +150 -exec rm -f {} \;
    find ${AI_ADMIN_LOG} -name "*${FILE_NAME}*.log" -mtime +150 -exec rm -f {} \;
    find ${AI_ADMIN_ERROR} -name "*${FILE_NAME}*.err" -mtime +150 -exec rm -f {} \;
    find ${AI_ADMIN_SUMMARY} -name "*${FILE_NAME}*.sum" -mtime +150 -exec rm -f {} \;
    find ${AI_SERIAL_REJECT} -name "*${FILE_NAME}*.rej" -mtime +150 -exec rm -f {} \;
    find ${AI_SERIAL_ARCH} -name "*${FILE_NAME}*.dat.zip" -mtime +150 -exec rm -f {} \;


##############################################################
## END OF WRAPPER SCRIPT
##############################################################
export End_Time=$(date)
echo "FINISH ${Job_Name}:  ${End_Time}."
echo "FINISH ${Job_Name}:  ${End_Time}." >> ${LOGFILE}
exit 0


#!/bin/bash -e
# This script is modified from cesm_postprocessing.sh,
# in the hope it will work in the similar way as diag_run
# yanchun.he@nersc.no, 18th Sept. 2025

# <<< conda initialize <<<
__conda_setup="$('/cluster/software/Miniforge3/24.1.2-0/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/cluster/software/Miniforge3/24.1.2-0/etc/profile.d/conda.sh" ]; then
        . "/cluster/software/Miniforge3/24.1.2-0/etc/profile.d/conda.sh"
    else
        export PATH="/cluster/software/Miniforge3/24.1.2-0/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Set variables that come from environment or CESM XML files
SRCROOT=/dummy/noresm/src
CASEROOT=/dummy/casename/src
CUPID_CASE_NAME=n1850.ne3pg3_tn21.noresm3_0_beta02.20250904
CUPID_CASE_ROOT=/nird/datalake/NS9560K/noresm3/cases
CUPID_ROOT=/diagnostics/CUPiD-src
CUPID_EXAMPLE='key_metrics'
CUPID_GEN_TIMESERIES=TRUE
CUPID_GEN_DIAGNOSTICS=TRUE
CUPID_GEN_HTML=TRUE
CUPID_BASELINE_CASE=null    #n1850.ne3pg3_tn21.noresm3_0_beta02.20250901
CUPID_BASELINE_ROOT=/nird/datalake/NS9560K/noresm3/cases
CUPID_TS_DIR=/scratch/$USER/noresm3/tseries
CUPID_STARTDATE=0001-01-01
CUPID_NYEARS=60
CUPID_BASE_STARTDATE=null
CUPID_BASE_NYEARS=null
CUPID_NTASKS=1
CUPID_RUN_ALL=FALSE
CUPID_RUN_ATM=FALSE
CUPID_RUN_OCN=FALSE
CUPID_RUN_LND=FALSE
CUPID_RUN_ICE=FALSE
CUPID_RUN_ROF=FALSE
CUPID_RUN_GLC=FALSE
CUPID_RUN_ADF=FALSE
CUPID_RUN_LDF=FALSE
CUPID_INFRASTRUCTURE_ENV=/diagnostics/CUPiD-env/cupid-infrastructure
CUPID_ANALYSIS_ENV=/diagnostics/CUPiD-env/cupid-analysis

############################################################
#     DON'T MODIFY THE PART BELOW, UNLESS YOU ARE AWARE
############################################################

## Welcome message
echo "-------------------------------------------------"
echo "Program:"
echo "/diagnostics/CUPiD-src/help_scripts/cupid_run"
echo ""
echo "Version: 0.1"
echo "-------------------------------------------------"

## Check all flags
if [ $# -eq 0 ] || [ $1 == "-h" ]; then
    echo "Short description:"
    echo "A wrapper script for running CUPiD for NorESM"
    echo " "
    echo "Basic usage:"
    echo " # model-obs comparison"
    echo " ${THIS_SCRIPT_NAME} -m [model] -c [test case name] -s [test case start yr] -e [test case end yr]
    echo " # model-model comparison"
    echo " ${THIS_SCRIPT_NAME} -m [model] -c [test case name] -s [test case start yr] -e [test case end yr] -c2 [cntl case name] -s2 [cntl case start yr] -e2 [cntl case end yr]"
    echo "Command-line options:"
    echo " -m, --model=MODEL                             Specify the diagnostics package (REQUIRED)."
    echo "                                               Valid arguments:"
    echo "                                                 all    : configure all available components."
    echo "                                                 atm    : atmospheric component"
    echo "                                                 lnd    : land component"
    echo "                                                 ice    : sea-ice component"
    echo "                                                 rof    : runoff component"
    echo "                                                 glc    : land-ice component"
    echo "                                                 adf    : ADF external package"
    #echo "                                                 ldf    : LDF external package"
    #echo "                                                 ilamb  : iLAMB external package"
    #echo "                                                 blom   : ocean package"
    #echo "                                                 hamocc : biogeochemistry package"
    echo " -c, -c1, --case=CASE1, --case1=CASE1          Test case simulation (OPTIONAL)."
    echo " -s, -s1, --start_yr=SYR1, --start_yr1=SYR1    Start year of test case climatology (OPTIONAL)."
    echo " -n, -n1, --nyr=NYR1, --nyr1=NYR1              Number of years of test case climatology (OPTIONAL)."
    echo " -c2, --case2=CASE2                            Control case simulation (OPTIONAL)."
    echo " -s2, --start_yr2=SYR2                         Start year of control case climatology (OPTIONAL)."
    echo " -n2, --nyr2=NYR2                              Number of years of control case climatology (OPTIONAL)."
    echo " -i, -i1, --input-dir=DIR, --input-dir1=DIR    Specify the directory where the test case history files are located (OPTIONAL)."
    echo "                                               Default is --input-dir=$HISTORY_PATH1"
    echo " -i2, --input-dir2=DIR                         Specify the directory where the control case history files are located (OPTIONAL)."
    echo "                                               Default is --input-dir=$HISTORY_PATH2"
    echo "                                               Default is to run both. Note that the time series are computed over the entire simulation."
    echo " -w, --web-dir=DIR                             Specify the directory where the html should be published (OPTIONAL)."
    echo "                                               Default is --web-dir=$WEB_PATH"
    echo " "
    echo "Examples:"
    #echo " ${THIS_SCRIPT_NAME} -m all -c N1850_f19_tn11_exp1 -s 21 -e 50 # model-obs diagnostics of case=N1850_f19_tn11_exp1 (climatology between yrs 21 and 50) for all model components."
    echo " ${THIS_SCRIPT_NAME} -m atm -c1 n1850.ne3pg3_tn21.noresm3_0_beta02.20250904  -s1 0001-01-01 -n1 60 -c2 n1850.ne3pg3_tn21.noresm3_0_beta02.20250901 -s2 0001-01-01 -n2 15 -i1 /nird/datalake/NS9560K/noresm3/cases -i2 /nird/datalake/NS9560K/noresm3/cases"
    echo " "
    exit 0
else
    while test $# -gt 0; do
        case "$1" in
            -c | -c1)
                shift
                if test $# -gt 0; then
                    CUPID_CASE_NAME=$1
                else
                    echo "ERROR: no test case specified (-c, -c1, --case, --case1)"
                    echo "*** EXITING THE SCRIPT"
                    exit 1
                fi
                shift
                ;;
            --case=* | --case1=*)
                CUPID_CASE_NAME=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            -c2)
                shift
                if test $# -gt 0; then
                    CUPID_BASELINE_CASE=$1
                else
                    echo "ERROR: no cntl case specified (-c2, --case2)"
                    echo "*** EXITING THE SCRIPT"
                    exit 1
                fi
                shift
                ;;
            --case2=*)
                CUPID_BASELINE_CASE=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            -s | -s1)
                shift
                if test $# -gt 0; then
                    CUPID_STARTDATE=$1
                else
                    echo "ERROR: no start yr of test case specified (-s, -s1, --start_yr, --start_yr1)"
                    echo "*** EXITING THE SCRIPT"
                    exit 1
                fi
                shift
                ;;
            --start_yr=* | --start_yr1=*)
                CUPID_STARTDATE=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            -s2)
                shift
                if test $# -gt 0; then
                    CUPID_BASE_STARTDATE=$1
                else
                    echo "ERROR: no start yr of cntl case specified (-s2, --start_yr2)"
                    echo "*** EXITING THE SCRIPT"
                    exit 1
                fi
                shift
                ;;
            --start_yr2=*)
                CUPID_BASE_STARTDATE=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            -n | -n1)
                shift
                if test $# -gt 0; then
                    CUPID_NYEARS=$1
                else
                    echo "ERROR: no end yr of test case specified (-e, -e1, --end_yr, --end_yr1)"
                    echo "*** EXITING THE SCRIPT"
                    exit 1
                fi
                shift
                ;;
            -n2)
                shift
                if test $# -gt 0; then
                    CUPID_BASE_NYEARS=$1
                else
                    echo "ERROR: no end yr of cntl case specified (-e2, --end_yr2)"
                    echo "*** EXITING THE SCRIPT"
                    exit 1
                fi
                shift
                ;;
            -i | -i1)
                shift
                if test $# -gt 0; then
                    CUPID_CASE_ROOT=$1
                else
                    echo "ERROR: no input directory specified (-i, --input-dir)"
                    echo "*** EXITING THE SCRIPT"
                    exit 1
                fi
                shift
                ;;
            --input-dir* | --input-dir1*)
                CUPID_CASE_ROOT=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            -i2)
                shift
                if test $# -gt 0; then
                    CUPID_BASELINE_ROOT=$1
                else
                    echo "ERROR: no input directory specified (-i2, --input-dir2)"
                    echo "*** EXITING THE SCRIPT"
                    exit 1
                fi
                shift
                ;;
            --input-dir2*)
                CUPID_BASELINE_ROOT=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            -m)
                shift
                if test $# -gt 0; then
                    USER_MODEL=$1
                else
                    echo "ERROR: no model specified (-m, --model)"
                         echo "Valid options: atm,lnd,ice,rof,glc,adf,ldf,all"
                    echo "*** EXITING THE SCRIPT"
                    exit 1
                fi
                shift
                ;;
            --model*)
                USER_MODEL=`echo $1 | sed -e 's/^[^=]*=//g'`
                shift
                ;;
            *)
                echo "ERROR: option $1 not allowed."
                echo "Run $BIN_DIR/$THIS_SCRIPT_NAME to see available options"
                echo "*** EXITING THE SCRIPT"
                exit 1
                ;;
        esac
    done
fi

add_years() {
  IFS='-' read -r YEAR MM DD <<< "$1"
  YEAR=$((10#$YEAR))  # Force base-10
  MM=$((10#$MM))
  DD=$((10#$DD))
  NEW_YEAR=`printf '%04d' "$((YEAR + $2))"`-`printf '%02d' "${MM}"`-`printf '%02d' "${DD}"`
  echo ${NEW_YEAR}
}

CUPID_ENDDATE=$(add_years ${CUPID_STARTDATE} ${CUPID_NYEARS})
CUPID_BASE_ENDDATE=$(add_years ${CUPID_BASE_STARTDATE} ${CUPID_BASE_NYEARS})

# DETERMINE WHICH PACKAGE TO RUN
if [ "$USER_MODEL" == "all" ]; then
    CUPID_RUN_ALL=TRUE
else
    USER_MODEL_SPACE=`echo $USER_MODEL | sed 's/,/ /g'`
    RUN_MODELS=(0 0 0 0 0 0)
    for model in $USER_MODEL_SPACE
    do
        if [ "$model" == "atm" ]; then
          CUPID_RUN_ATM=TRUE
          CUPID_RUN_ADF=TRUE
        elif [ "$model" == "lnd" ]; then
          CUPID_RUN_LND=TRUE
          CUPID_RUN_LDF=FALSE
        elif [ "$model" == "ice" ]; then
          CUPID_RUN_ICE=TRUE
        elif [ "$model" == "rof" ]; then
          CUPID_RUN_ROF=TRUE
        elif [ "$model" == "glc" ]; then
          CUPID_RUN_GLC=TRUE
        fi
    done
fi

# Create directory for running CUPiD
mkdir -p cupid-postprocessing
cd cupid-postprocessing

# If CUPID_RUN_ALL is TRUE, we don't add any component flags.
# The lack of any component flags tells CUPiD to run all components.
CUPID_FLAG_STRING=""
if [ "${CUPID_RUN_ALL}" == "FALSE" ]; then
  if [ "${CUPID_RUN_ATM}" == "TRUE" ]; then
    CUPID_FLAG_STRING+=" -atm"
  fi
  if [ "${CUPID_RUN_OCN}" == "TRUE" ]; then
    CUPID_FLAG_STRING+=" -ocn"
  fi
  if [ "${CUPID_RUN_LND}" == "TRUE" ]; then
    CUPID_FLAG_STRING+=" -lnd"
  fi
  if [ "${CUPID_RUN_ICE}" == "TRUE" ]; then
    CUPID_FLAG_STRING+=" -ice"
  fi
  if [ "${CUPID_RUN_ROF}" == "TRUE" ]; then
    CUPID_FLAG_STRING+=" -rof"
  fi
  if [ "${CUPID_RUN_GLC}" == "TRUE" ]; then
    CUPID_FLAG_STRING+=" -glc"
  fi
  if [ "${CUPID_FLAG_STRING}" == "" ]; then
    echo "If CUPID_RUN_ALL is False, user must set at least one component"
    exit 1
  fi
fi

if [ "${CUPID_NTASKS}" == "1" ]; then
  echo "CUPiD will not use dask in any notebooks"
  CUPID_FLAG_STRING+=" --serial"
fi

if [ "${CUPID_RUN_ALL}" == "TRUE" ]; then
  echo "CUPID_RUN_ALL is True, running diagnostics for all components"
fi

# Use cupid-infrastructure environment for running these scripts
# Note: on derecho, the cesmdev module creates a python conflict
#       by setting $PYTHONPATH; since this is conda-based we
#       want an empty PYTHONPATH environment variable
#unset PYTHONPATH
conda activate ${CUPID_INFRASTRUCTURE_ENV}

# 1. Generate CUPiD config file
${CUPID_ROOT}/helper_scripts/generate_cupid_config_for_noresm_case.py \
   --case-root ${CASEROOT} \
   --cesm-root ${SRCROOT} \
   --cupid-case-name ${CUPID_CASE_NAME} \
   --cupid-case-root ${CUPID_CASE_ROOT} \
   --cupid-root ${CUPID_ROOT} \
   --adf-output-root ${PWD} \
   --cupid-example ${CUPID_EXAMPLE} \
   --cupid-baseline-case ${CUPID_BASELINE_CASE} \
   --cupid-baseline-root ${CUPID_BASELINE_ROOT} \
   --cupid-ts-dir ${CUPID_TS_DIR} \
   --cupid-startdate ${CUPID_STARTDATE} \
   --cupid-enddate ${CUPID_ENDDATE} \
   --cupid-base-startdate ${CUPID_BASE_STARTDATE} \
   --cupid-base-enddate ${CUPID_BASE_ENDDATE} \

# 2. Generate ADF config file
if [ "${CUPID_RUN_ADF}" == "TRUE" ]; then
  ${CUPID_ROOT}/helper_scripts/generate_adf_config_file.py \
     --cupid-config-loc . \
     --adf-template ${CUPID_ROOT}/externals/ADF/config_noresm_ipcc.yaml \
     --out-file adf_config.yml
fi
# 3. Generate LDF config file
if [ "${CUPID_RUN_LDF}" == "TRUE" ]; then
  ${CUPID_ROOT}/helper_scripts/generate_ldf_config_file.py \
     --cupid-config-loc . \
     --ldf-template ${CUPID_ROOT}/externals/LDF/config_clm_unstructured_plots.yaml \
     --out-file ldf_config.yml
fi

# 4. Generate timeseries files
if [ "${CUPID_GEN_TIMESERIES}" == "TRUE" ]; then
   ${CUPID_ROOT}/cupid/run_timeseries.py ${CUPID_FLAG_STRING} ./config.yml
fi

# 5. Run ADF
if [ "${CUPID_RUN_ADF}" == "TRUE" ]; then
  conda deactivate
  conda activate ${CUPID_ANALYSIS_ENV}
  ${CUPID_ROOT}/externals/ADF/run_adf_diag adf_config.yml
fi

# 6. Run LDF
if [ "${CUPID_RUN_LDF}" == "TRUE" ]; then
  conda deactivate
  conda activate ${CUPID_ANALYSIS_ENV}
  ${CUPID_ROOT}/externals/LDF/run_adf_diag ldf_config.yml
fi

# 7. Run CUPiD and build webpage
conda deactivate
conda activate ${CUPID_INFRASTRUCTURE_ENV}
if [ "${CUPID_GEN_DIAGNOSTICS}" == "TRUE" ]; then
  ${CUPID_ROOT}/cupid/run_diagnostics.py ${CUPID_FLAG_STRING} ./config.yml
fi
if [ "${CUPID_GEN_HTML}" == "TRUE" ]; then
  ${CUPID_ROOT}/cupid/generate_webpage.py
fi

# 8. Move webpage to NIRD www/
YYYY1=$(echo ${CUPID_STARTDATE} |cut -d"-" -f1)
YYYY2=$(echo ${CUPID_ENDDATE}   |cut -d"-" -f1)
if [ ${CUPID_BASE_ENDDATE} != "NULL" ]; then
    YYYY1_BASE=$(echo ${CUPID_BASE_STARTDATE} |cut -d"-" -f1)
    YYYY2_BASE=$(echo ${CUPID_BASE_ENDDATE}   |cut -d"-" -f1)
fi
if [ -z ${YYYY1_BASE} ]; then
    case_dir=${CUPID_CASE_NAME}_${YYYY1}-${YYYY2}_vs_obs
else
    case_dir=${CUPID_CASE_NAME}_${YYYY1}-${YYYY2}_vs_${CUPID_BASELINE_CASE}_${YYYY1_BASE}-${YYYY2_BASE}
fi

www_root=/nird/datalake/NS2345K/www/diagnostics/CUPiD/$USER/
mkdir -p ${www_root}/${case_dir}
echo "Move generated www pages to ${www_root}/${case_dir}"
rsync -azu --remove-source-files computed_notebooks/_build/ ${www_root}/${case_dir}/

echo "************"
echo "  ALL DONE  "
echo "************"

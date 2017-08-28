#! /usr/bin/env bash

function usage {
    echo "usage: $(basename $0) [-onh] <cas_dir> <output_dir>"
    echo "  -o --original-ts         location of original training set to be added"
    echo "  -n --new-ts              add new observations from server stats"
    echo "  -h --help                display help"
    exit 1
}

if [[ "${#}" < 2 ]]
then
    usage
fi

datatypes=("antibody" "catalyticact" "expression_cluster" "geneint" "geneprod" "genereg" "newmutant" "otherexpr" \
"overexpr" "rnai" "seqchange" "structcorr")

CAS_DIR=""
OUT_DIR=""
ORIGINAL_TS_DIR=""
USE_NEW_TS=0

while [[ $# -gt 1 ]]
do
key=$1

case $key in
    -o|--original-ts)
    shift
    if [[ -d $1 ]]
    then
        ORIGINAL_TS_DIR=$1
    else
        usage
    fi
    shift
    ;;
    -n|--new-ts)
    USE_NEW_TS=1
    shift
    ;;
    -h|--help)
    usage
    ;;
    *)
    if [[ -d $key ]]
    then
        CAS_DIR="$key"
    else
        usage
    fi
    shift
    if [ -d $1 ]
    then
        OUT_DIR=$1
    else
        usage
    fi
    shift
    ;;
esac
done

if [[ ${CAS_DIR} == "" || ${OUT_DIR} == "" ]]
then
    usage
fi

for datatype in ${datatypes[@]}
do
    mkdir -p ${OUT_DIR}/${datatype}/positive
    mkdir -p ${OUT_DIR}/${datatype}/negative
    mkdir -p ${OUT_DIR}/${datatype}/valp_tp
    mkdir -p ${OUT_DIR}/${datatype}/valp_fp
    mkdir -p ${OUT_DIR}/${datatype}/valn_tn
    mkdir -p ${OUT_DIR}/${datatype}/valn_fn
done

if [[ ${USE_NEW_TS} == 1 ]]
then
    for datatype in ${datatypes[@]}
    do
        tmpfile_valp_tp=$(mktemp)
        tmpfile_valp_fp=$(mktemp)
        tmpfile_valn_tn=$(mktemp)
        tmpfile_valn_fn=$(mktemp)
        wget -O - -o /dev/null "http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two736&listDatatype="${datatype}"&method=svm%20"pos"%20val%20tp&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on" | grep -o "name=\"specific_papers\">.*</textarea>" | grep -o "[0-9]\{1,\}" > ${tmpfile_valp_tp}
        wget -O - -o /dev/null "http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two736&listDatatype="${datatype}"&method=svm%20"pos"%20val%20fp&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on" | grep -o "name=\"specific_papers\">.*</textarea>" | grep -o "[0-9]\{1,\}" > ${tmpfile_valp_fp}
        find "${CAS_DIR}" -name *.tpcas.gz | grep -f ${tmpfile_valp_tp} | xargs -I {} cp "{}" ${OUT_DIR}/${datatype}/valp_tp/
        find "${CAS_DIR}" -name *tpcas.gz | grep -f ${tmpfile_valp_fp} | xargs -I {} cp "{}" ${OUT_DIR}/${datatype}/valp_fp/
        wget -O - -o /dev/null "http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two736&listDatatype="${datatype}"&method=svm%20"neg"%20val%20fn&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on" | grep -o "name=\"specific_papers\">.*</textarea>" | grep -o "[0-9]\{1,\}" > ${tmpfile_valn_fn}
        wget -O - -o /dev/null "http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two736&listDatatype="${datatype}"&method=svm%20"neg"%20val%20tn&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on" | grep -o "name=\"specific_papers\">.*</textarea>" | grep -o "[0-9]\{1,\}" > ${tmpfile_valn_tn}
        find "${CAS_DIR}" -name *.tpcas.gz | grep -f ${tmpfile_valn_tn} | xargs -I {} cp "{}" ${OUT_DIR}/${datatype}/valn_tn/
        find "${CAS_DIR}" -name *tpcas.gz | grep -f ${tmpfile_valn_fn} | xargs -I {} cp "{}" ${OUT_DIR}/${datatype}/valn_fn/
        cp ${OUT_DIR}/${datatype}/valp_tp/* ${OUT_DIR}/${datatype}/positive/
        cp ${OUT_DIR}/${datatype}/valp_fp/* ${OUT_DIR}/${datatype}/negative/
        cp ${OUT_DIR}/${datatype}/valn_tn/* ${OUT_DIR}/${datatype}/negative/
        cp ${OUT_DIR}/${datatype}/valn_fn/* ${OUT_DIR}/${datatype}/positive/
        rm ${tmpfile_valp_tp}
        rm ${tmpfile_valp_fp}
        rm ${tmpfile_valn_tn}
        rm ${tmpfile_valn_fn}
    done
fi

if [[ ${ORIGINAL_TS_DIR} != "" ]]
then
    for datatype in $(ls ${ORIGINAL_TS_DIR})
    do
        find "${CAS_DIR}" -name *.tpcas.gz | grep -f ${ORIGINAL_TS_DIR}/${datatype}/${datatype}_positive | xargs -I {} cp "{}" ${OUT_DIR}/${datatype}/positive/
        find "${CAS_DIR}" -name *.tpcas.gz | grep -f ${ORIGINAL_TS_DIR}/${datatype}/${datatype}_negative | xargs -I {} cp "{}" ${OUT_DIR}/${datatype}/negative/
    done
fi

# remove supplemental materials
find ${OUT_DIR} -name *.sup.* | xargs rm
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
done

if [[ ${USE_NEW_TS} == 1 ]]
then
    for datatype in ${datatypes[@]}
    do
        tmpfile_positive=$(mktemp)
        tmpfile_negative=$(mktemp)
        wget -O - -o /dev/null "http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two736&listDatatype="${datatype}"&method=svm%20"pos"%20val%20tp&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on" | grep -o "name=\"specific_papers\">.*</textarea>" | grep -o "[0-9]\{1,\}" > ${tmpfile_positive}
        wget -O - -o /dev/null "http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two736&listDatatype="${datatype}"&method=svm%20"neg"%20val%20tp&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on" | grep -o "name=\"specific_papers\">.*</textarea>" | grep -o "[0-9]\{1,\}" > ${tmpfile_negative}
        find "${CAS_DIR}" -name *.tpcas.gz | grep -f ${tmpfile_positive} | xargs -I {} cp "{}" ${OUT_DIR}/${datatype}/positive/
        find "${CAS_DIR}" -name *tpcas.gz | grep -f ${tmpfile_negative} | xargs -I {} cp "{}" ${OUT_DIR}/${datatype}/negative/
        rm ${tmpfile_positive}
        rm ${tmpfile_negative}
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
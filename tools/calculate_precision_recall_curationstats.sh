#!/usr/bin/env bash

### calculate estimated precision and recall values on data obtained from curation status page by balancing the
### validation and assuming that the curator should have evaluated an equal number of positive and negative results

function usage {
    echo "usage: $(basename $0) [-e]"
    echo "  -e --estimate-true-recall  use a weighting scheme based on the ratio between positive and negative validated papers to estimate true recall and precision"
    echo "  -h --help                  display help"
    exit 1
}

ESTIMATE="false"

models=("KNN" "SVM_LINEAR" "SVM_NONLINEAR" "TREE" "RF" "MLP" "NAIVEB" "GAUSS" "LDA" "XGBOOST")

while [[ $# -gt 0 ]]
do
key=$1

case $key in
    -h|--help)
    usage
    ;;
    -e|--estimate-true-recall)
    ESTIMATE="true"
    shift
    ;;
    -h|--help)
    usage
    ;;
    *)
    shift
    ;;
esac
done

datatypes=("antibody" "catalyticact" "expression_cluster" "geneint" "geneprod" "genereg" "newmutant" "otherexpr" \
"overexpr" "rnai" "seqchange" "structcorr")
dtindices=(1 3 5 7 8 9 14 16 17 19 20 22)

tmpfile=$(mktemp)
wget -o /dev/null --post-data="select_curator=two736&action=Curation+Statistics+Page&checkbox_all_datatypes=all&checkbox_all_flagging_methods=all" "http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi" -O ${tmpfile}

echo -e "DATATYPE\tMODEL\tTP\tFP\tTN\tFN\tPRECISION\tRECALL\tF_MEASURE\tACCURACY"

for ((i=0; i<$((${#datatypes[@]})); i++))
do
    idx=$((${dtindices[$i]} + 1))
    tot_p=0
    tmp=$(grep -o -P "SVM positive any</a>.*?</tr>" ${tmpfile} | awk -v col=${idx} 'BEGIN{FS="<td colspan=\"1\">"} {print $col}' | grep -oP ">\K[0-9]*")
    if [[ ${tmp} != "" ]]
    then
        tot_p=${tmp}
    fi
    tot_vp=0
    tmp=$(grep -o -P "SVM positive any validated</a>.*?</tr>" ${tmpfile} | awk -v col=${idx} 'BEGIN{FS="<td colspan=\"1\">"} {print $col}' | grep -oP ">\K[0-9]*")
    if [[ ${tmp} != "" ]]
    then
        tot_vp=${tmp}
    fi
    tot_n=0
    tmp=$(grep -o -P "SVM negative</a>.*?</tr>" ${tmpfile} | awk -v col=${idx} 'BEGIN{FS="<td colspan=\"1\">"} {print $col}' | grep -oP ">\K[0-9]*")
    if [[ ${tmp} != "" ]]
    then
        tot_n=${tmp}
    fi
    tot_vn=0
    tmp=$(grep -o -P "SVM negative validated</a>.*?</tr>" ${tmpfile} | awk -v col=${idx} 'BEGIN{FS="<td colspan=\"1\">"} {print $col}' | grep -oP ">\K[0-9]*")
    if [[ ${tmp} != "" ]]
    then
        tot_vn=${tmp}
    fi
    tp=0
    tmp=$(grep -o -P "SVM positive any validated true  positive</a>.*?</tr>" ${tmpfile} | awk -v col=${idx} 'BEGIN{FS="<td colspan=\"1\">"} {print $col}' | grep -oP ">\K[0-9]*")
    if [[ ${tmp} != "" ]]
    then
        tp=${tmp}
    fi
    fp=0
    tmp=$(grep -o -P "SVM positive any validated false positive</a>.*?</tr>" ${tmpfile} | awk -v col=${idx} 'BEGIN{FS="<td colspan=\"1\">"} {print $col}' | grep -oP ">\K[0-9]*")
    if [[ ${tmp} != "" ]]
    then
        fp=${tmp}
    fi
    tn=0
    tmp=$(grep -o -P "SVM negative validated true  negative</a>.*?</tr>" ${tmpfile} | awk -v col=${idx} 'BEGIN{FS="<td colspan=\"1\">"} {print $col}' | grep -oP ">\K[0-9]*")
    if [[ ${tmp} != "" ]]
    then
        tn=${tmp}
    fi
    fn=0
    tmp=$(grep -o -P "SVM negative validated false negative</a>.*?</tr>" ${tmpfile} | awk -v col=${idx} 'BEGIN{FS="<td colspan=\"1\">"} {print $col}' | grep -oP ">\K[0-9]*")
    if [[ ${tmp} != "" ]]
    then
        fn=${tmp}
    fi

    if [[ ${tot_vn} != "0" ]]
    then
        if [[ ${ESTIMATE} == "true" ]]
        then
            pn_rate=$(echo "("${tot_n}"*"${tot_vp}")/("${tot_vn}"*"${tot_p}")" | bc -l)
        else
            pn_rate="1"
        fi
        tn=$(echo ${tn}"*"${pn_rate} | bc -l)
        fn=$(echo ${fn}"*"${pn_rate} | bc -l)

        precision=0
        if [[ $(echo ${tp}"+"${fp}">0" | bc -l) != "0" ]]; then precision=$(echo ${tp}"/("${tp}"+"${fp}")" | bc -l); fi
        recall=0
        if [[ $(echo ${tp}"+"${fn}">0" | bc -l) != "0" ]]; then recall=$(echo ${tp}"/("${tp}"+"${fn}")" | bc -l); fi

        fmeasure=0
        if [[ $(echo ${precision}"+"${recall}">0" | bc -l) != "0" ]]; then fmeasure=$(echo "2*("${precision}"*"${recall}")/("${precision}"+"${recall}")" | bc -l); fi

        accuracy=0
        if [[ $(echo ${tp}"+"${tn}"+"${fp}"+"${fn}">0" | bc -l) != "0" ]]; then accuracy=$(echo "("${tp}"+"${tn}")/("${tp}"+"${tn}"+"${fp}"+"${fn}")" | bc -l); fi

        echo -e ${datatypes[$i]}"\tCURRENT_MODEL (SVM_NONLINEAR)\t"${tp}"\t"${fp}"\t"${tn}"\t"${fn}"\t"${precision}"\t"${recall}"\t"${fmeasure}"\t"${accuracy}
    else
        echo -e ${datatypes[$i]}"\tCURRENT_MODEL (SVM_NONLINEAR)\t"${tp}"\t"${fp}"\t"${tn}"\t"${fn}"\tNA\tNA\tNA\tNA"
    fi
done

rm ${tmpfile}


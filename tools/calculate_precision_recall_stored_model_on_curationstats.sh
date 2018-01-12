#!/usr/bin/env bash

### calculate estimated precision and recall values on data obtained from previously calculated predictions by balancing
### the validation and assuming that the curator should have evaluated an equal number of positive and negative results
### according to the numbers obtained from the curation status page

function usage {
    echo "usage: $(basename $0) [-e] <input_dir>"
    echo "  -e --estimate-true-recall  use a weighting scheme based on the ratio between positive and negative validated papers to estimate true recall and precision"
    echo "  -h --help                  display help"
    exit 1
}

ESTIMATE="false"
stored_predictions_root_dir=""

models=("KNN" "SVM_LINEAR" "SVM_NONLINEAR" "TREE" "RF" "MLP" "NAIVEB" "GAUSS" "LDA" "XGBOOST")

while [[ $# -gt 0 ]]
do
key=$1

case $key in
    -e|--estimate-true-recall)
    ESTIMATE="true"
    shift
    ;;
    -h|--help)
    usage
    ;;
    *)
    if [[ -d $key ]]
    then
        stored_predictions_root_dir="$key"
    else
        usage
    fi
    shift
    ;;
esac
done

if [[ ${stored_predictions_root_dir} == "" ]]
then
    usage
fi

datatypes=("antibody" "catalyticact" "expression_cluster" "geneint" "geneprod" "genereg" "newmutant" "otherexpr" \
"overexpr" "rnai" "seqchange" "structcorr")
dtindices=(1 3 5 7 8 9 13 15 16 18 19 21)
models=("KNN" "SVM_LINEAR" "SVM_NONLINEAR" "TREE" "RF" "MLP" "NAIVEB" "GAUSS" "LDA" "XGBOOST")

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
    for ((j=0; j<$((${#models[@]})); j++))
    do
        valp_tp_p=$(awk '{if ($2 == 1) print $0}' ${stored_predictions_root_dir}/${datatypes[$i]}/${models[$j]}/prediction_valp_tp.csv | wc -l)
        valp_tp_n=$(awk '{if ($2 == 0) print $0}' ${stored_predictions_root_dir}/${datatypes[$i]}/${models[$j]}/prediction_valp_tp.csv | wc -l)
        valp_fp_p=$(awk '{if ($2 == 1) print $0}' ${stored_predictions_root_dir}/${datatypes[$i]}/${models[$j]}/prediction_valp_fp.csv | wc -l)
        valp_fp_n=$(awk '{if ($2 == 0) print $0}' ${stored_predictions_root_dir}/${datatypes[$i]}/${models[$j]}/prediction_valp_fp.csv | wc -l)
        valn_tn_p=$(awk '{if ($2 == 1) print $0}' ${stored_predictions_root_dir}/${datatypes[$i]}/${models[$j]}/prediction_valn_tn.csv | wc -l)
        valn_tn_n=$(awk '{if ($2 == 0) print $0}' ${stored_predictions_root_dir}/${datatypes[$i]}/${models[$j]}/prediction_valn_tn.csv | wc -l)
        valn_fn_p=$(awk '{if ($2 == 1) print $0}' ${stored_predictions_root_dir}/${datatypes[$i]}/${models[$j]}/prediction_valn_fn.csv | wc -l)
        valn_fn_n=$(awk '{if ($2 == 0) print $0}' ${stored_predictions_root_dir}/${datatypes[$i]}/${models[$j]}/prediction_valn_fn.csv | wc -l)

        if [[ ${tot_vn} != "0" ]]
        then
            if [[ ${ESTIMATE} == "true" ]]
            then
                pn_rate=$(echo "("${tot_n}"*"${tot_vp}")/("${tot_vn}"*"${tot_p}")" | bc -l)
            else
                pn_rate="1"
            fi
            valn_tn_p=$(echo ${valn_tn_p}"*"${pn_rate} | bc -l)
            valn_tn_n=$(echo ${valn_tn_n}"*"${pn_rate} | bc -l)
            valn_fn_p=$(echo ${valn_fn_p}"*"${pn_rate} | bc -l)
            valn_fn_n=$(echo ${valn_fn_n}"*"${pn_rate} | bc -l)

            tp=$(echo ${valp_tp_p}"+"${valn_fn_p} | bc -l)
            fp=$(echo ${valp_fp_p}"+"${valn_tn_p} | bc -l)
            tn=$(echo ${valn_tn_n}"+"${valp_fp_n} | bc -l)
            fn=$(echo ${valn_fn_n}"+"${valp_tp_n} | bc -l)

            precision=0
            if [[ $(echo ${tp}"+"${fp}">0" | bc -l) != "0" ]]; then precision=$(echo ${tp}"/("${tp}"+"${fp}")" | bc -l); fi
            recall=0
            if [[ $(echo ${tp}"+"${fn}">0" | bc -l) != "0" ]]; then recall=$(echo ${tp}"/("${tp}"+"${fn}")" | bc -l); fi

            fmeasure=0
            if [[ $(echo ${precision}"+"${recall}">0" | bc -l) != "0" ]]; then fmeasure=$(echo "2*("${precision}"*"${recall}")/("${precision}"+"${recall}")" | bc -l); fi

            accuracy=0
            if [[ $(echo ${tp}"+"${tn}"+"${fp}"+"${fn}">0" | bc -l) != "0" ]]; then accuracy=$(echo "("${tp}"+"${tn}")/("${tp}"+"${tn}"+"${fp}"+"${fn}")" | bc -l); fi
            echo -e ${datatypes[$i]}"\t"${models[$j]}"\t"${tp}"\t"${fp}"\t"${tn}"\t"${fn}"\t"${precision}"\t"${recall}"\t"${fmeasure}"\t"${accuracy}
        else
            echo -e ${datatypes[$i]}"\t"${models[$j]}"\tNA\tNA\tNA\t\tNA\tNA\tNA\tNA"
        fi
    done
done

rm ${tmpfile}


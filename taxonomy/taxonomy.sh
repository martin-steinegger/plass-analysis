#!/bin/bash -ex

PROTEIN_READS="$1"
PROTEIN_ASSEMLIES="$2"
RESULTS="$3"
MMSEQS="mmseqs"

#export RUNNER="mpirun --pernode --bind-to none"
export RUNNER=

removeStopCodon() {
    local INDB="$1"
    local OUTDB="$2"
    local TMPOUT="$3"

    $MMSEQS prefixid "$INDB" "${TMPOUT}/prefix" --tsv
    tr -d '*' < "${TMPOUT}/prefix" > "${TMPOUT}/prefix_no_stop"
    $MMSEQS tsv2db "${TMPOUT}/prefix_no_stop" "${OUTDB}"
    rm -f "${TMPOUT}/prefix" "${TMPOUT}/prefix_no_stop"
}

taxanalysis() {
    local READDB="$1"
    local SEQDB="$2"
    local TMPOUT="$3"
    local DBPATH="$4"

    mkdir -p "${DBPATH}" 
    local DB="${DBPATH}/uniclust90_2017_07_seed_db"
    local KB="${DBPATH}/uniprot_sprot_trembl.dat"

    if [[ ! -e "${DB}" ]]; then
        mkdir -p "${DBPATH}" && cd "${DBPATH}"
        wget http://wwwuser.gwdg.de/~compbiol/uniclust/2017_10/uniclust90_2017_10.tar.gz
        tar xzvf "uniclust90_2017_10.tar.gz"
        $MMSEQS createdb uniclust90_2017_10/uniclust90_2017_07_seed.fasta "${DB}"
        rm -rf uniclust90_2017_10
        cd -
        mkdir -p "${DBPATH}/kb" && cd "${DBPATH}/kb"
        wget ftp://ftp.ebi.ac.uk/pub/databases/uniprot/previous_releases/release-2017_07/knowledgebase/knowledgebase2017_07.tar.gz
        tar xzvf knowledgebase2017_07.tar.gz
        gunzip -c uniprot_sprot.dat.gz > "${KB}"
        gunzip -c uniprot_trembl.dat.gz >> "${KB}"
        cd -
        rm -rf "${DBPATH}/kb"
    fi

    if [[ ! -e "${DB}.mapping" ]]; then
        $MMSEQS convertkb "${KB}" "${DB}_kb" --kb-columns OX --mapping-file "${DB}.lookup"
        $MMSEQS prefixid "${DB}_kb_OX" "${DB}.mapping_tmp" --tsv
        awk '{ match($2, /=([^ ;]+)/, a); print $1"\t"a[1]; }' "${DB}.mapping_tmp" > "${DB}.mapping"
        rm -f "${DB}.mapping_tmp"
    fi

    local NCBI="${DBPATH}/ncbi"
    if [[ ! -e "${NCBI}/nodes.dmp" ]] || [[ ! -e "${NCBI}/names.dmp" ]]; then
        mkdir -p "${NCBI}" && cd "${NCBI}"
        wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
        tar xzvf taxdump.tar.gz
        cd -
    fi

    mkdir -p "${TMPOUT}"
    if [[ ! -e "${TMPOUT}/reads" ]]; then
        removeStopCodon "${READDB}" "${TMPOUT}/reads" "${TMPOUT}"
        ln -s "${READDB}_h" "${TMPOUT}/reads_h"
        ln -s "${READDB}_h.index" "${TMPOUT}/reads_h.index"
    fi
    READDB="${TMPOUT}/reads"

    if [[ ! -e "${TMPOUT}/assembled" ]]; then
        removeStopCodon "${SEQDB}" "${TMPOUT}/assembled" "${TMPOUT}"
        ln -s "${SEQDB}_h" "${TMPOUT}/assembled_h"
        ln -s "${SEQDB}_h.index" "${TMPOUT}/assembled_h.index"
    fi
    SEQDB="${TMPOUT}/assembled"

    if [[ ! -e "${TMPOUT}/taxa-phylum.tsv" ]]; then
        $MMSEQS taxonomy "${SEQDB}" "${DB}" "${DB}.mapping" "${NCBI}" "${TMPOUT}/taxa_db" "${TMPOUT}/tmp_lca" \
		    --start-sens 1 -s 6 --sens-steps 3 --lca-ranks "phylum:superphylum:subkingdom:kingdom:superkingdom"
        $MMSEQS prefixid "${TMPOUT}/taxa_db" "${TMPOUT}/taxa-phylum.tsv" --tsv
    fi

    THRESHOLD=0.9
    if [[ ! -e "${TMPOUT}/tmp_read/aln_1_sort_${THRESHOLD}" ]]; then
        mkdir -p "${TMPOUT}/tmp_read"
        $MMSEQS map "${READDB}" "${SEQDB}" "${TMPOUT}/tmp_read/aln_1_sort_${THRESHOLD}" --min-seq-id ${THRESHOLD} -c 0.9 --cov-mode 2
    fi

    if [[ ! -e "${TMPOUT}/abundance_${THRESHOLD}.tsv" ]]; then
        $MMSEQS filterdb "${TMPOUT}/tmp_read/aln_1_sort_${THRESHOLD}" "${TMPOUT}/tmp_read/aln_1_top1_${THRESHOLD}" --extract-lines 1
		$MMSEQS swapresults "${READDB}" "${SEQDB}" "${TMPOUT}/tmp_read/aln_1_top1_${THRESHOLD}" "${TMPOUT}/mapped_reads_${THRESHOLD}"
        $MMSEQS result2stats "${SEQDB}" "${SEQDB}" "${TMPOUT}/mapped_reads_${THRESHOLD}" "${TMPOUT}/mapped_linecount_${THRESHOLD}" --stat linecount
        $MMSEQS prefixid "${TMPOUT}/mapped_linecount_${THRESHOLD}" "${TMPOUT}/abundance_${THRESHOLD}.tsv" --tsv
    fi

	if [[ ! -e "${TMPOUT}/coverage_${THRESHOLD}.tsv" ]];then
		$MMSEQS swapresults "${READDB}" "${SEQDB}" "${TMPOUT}/tmp_read/aln_1_sort_${THRESHOLD}" "${TMPOUT}/mapped_reads_all_${THRESHOLD}"
		$MMSEQS prefixid "${TMPOUT}/mapped_reads_all_${THRESHOLD}" "${TMPOUT}/mapped_reads_all_${THRESHOLD}.tsv" --tsv
		awk 'BEGIN { last = ""; cov = 0; lastContigLength = 0; } $1 != last { if (NR > 1) { print last"\t"cov"\t"lastContigLength; cov = 0; }; last = $1; } { currentCov = (($10 - $9) / $8); cov = cov + currentCov; lastContigLength = $8; } END { if (NR > 1) { print last"\t"cov"\t"lastContigLength; cov = 0; }; }' "${TMPOUT}/mapped_reads_all_${THRESHOLD}.tsv" > "${TMPOUT}/coverage_${THRESHOLD}.tsv"
		rm -f "${TMPOUT}/mapped_reads_all_${THRESHOLD}.tsv"
    fi

    ###### Merging
    READ_COUNT="$(cat ${READDB}.index  | wc -l)"
    LC_ALL=C join <(LC_ALL=C sort -T /dev/shm --parallel 16 "${TMPOUT}/taxa-phylum.tsv") <(LC_ALL=C sort -T /dev/shm --parallel 16 "${TMPOUT}/abundance_${THRESHOLD}.tsv") -o "1.5 2.2 1.3 1.2" -t $'\t' > "${TMPOUT}/taxa-abundance_${THRESHOLD}.tsv"
    awk -F$'\t' -v totalReads="${READ_COUNT}"  'function selectRank(levels, taxon) { if (taxon == 1) return "Life"; if (taxon == 0) return "Unknown"; n = split(levels, arr, ":"); for (i = 1; i <= n; i++) { if (arr[i] ~ /^uc_/) { continue; } if (arr[i] == "unknown") { continue; } return arr[i]; } if (taxon == 131567) { return "Cellular Organisms"; } return "Unclassified"; } { rank = selectRank($1, $4); total = total + $2; if (rank in f) { f[rank] = f[rank] + $2; } else { f[rank] = 1; } } END { for (i in f) { print i"\t"f[i]"\t"f[i]/total"\t"totalReads; } }' "${TMPOUT}/taxa-abundance_${THRESHOLD}.tsv" | sort -n -k2 -r > "${TMPOUT}/taxa-phylum_${THRESHOLD}.hist"
}

taxanalysis "${PROTEIN_READS}" ${PROTEIN_ASSEMLIES}" "${RESULTS}" 

#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH -t 6:30:00
#SBATCH -A fv3-cpu
#SBATCH -q batch
#SBATCH -J anome
#SBATCH -o log1
#SBATCH -e log1

# ==========================================================
# Climate Lead-Month Processing Script
# - Reorganize forecast by lead month
# - Extract corresponding ANA/OBS
# - Compute climatology and anomaly
# - Compute seasonal means
# ==========================================================

set -x
export OMP_NUM_THREADS=8
module load cdo
source config.diag.comp.t2m

echo "WORKDIR = $WORKDIR"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# ==========================================================
# Utility Functions
# ==========================================================

file_exists_or_exit() {
    [[ -f "$1" ]] || { echo "ERROR: Missing file $1"; exit 1; }
}

get_anafile() {
    local type=$1
    local varana=$2

    case "$type" in
        OISST)
            echo "$ANADATADIR/$OISSTFILENAME"
            ;;
        CERES_CLD)
            echo "$ANADATADIR/$CERESFILENAME_CLD"
            ;;
        CERES)
            echo "$ANADATADIR/$CERESFILENAME"
            ;;
        CERES_SFC)
            echo "$ANADATADIR/$CERESFILENAME_SFC"
            ;;
        ERA5_3D)
            echo "$ANADATADIR/ERA5_3D/${varana}.1994-2025.mon.1p0.nc"
            ;;
        *)
            echo "$ANADATADIR/$ERAFILENAME"
            ;;
    esac
}

reset_to_month_start() {
    local infile=$1
    local outfile=$2

    file_exists_or_exit "$infile"

    local first_date
    first_date=$(cdo -s showdate "$infile" | awk '{print $1}' | head -1)

    local year=${first_date:0:4}
    local month=${first_date:5:2}

    cdo settaxis,"${year}-${month}-01,00:00:00","1year" \
        "$infile" "$outfile"
}

compute_climate_and_anom() {
    local input=$1
    local prefix=$2

    cdo ymonmean "$input" "${prefix}.nc"
    cdo ymonsub  "$input" "${prefix}.nc" \
                 "${prefix}.anom.nc"
}

compute_seasonal_mean() {
    local prefix=$1   # exp or ANA
    local icdate=$2
    local CASE_NUM=$3
    local var=$4
    local range=$5

    IFS='-' read start end <<< "$range"

    files=()
    for m in $(seq $start $end); do
        files+=("${prefix}.${icdate}.${CASE_NUM}yr.${var}.leadmon${m}.nc")
    done

    outfile="${prefix}.${icdate}.${CASE_NUM}yr.${var}.leadmon${range}.nc"

    for f in "${files[@]}"; do
        [[ -f "$f" ]] || { echo "Missing $f"; return; }
    done

    cdo ensmean "${files[@]}" "$outfile"
}

# ==========================================================
# Check CDATE consistency
# ==========================================================

first_mmdd=""
for CDATE in $CDATELIST; do
    mmdd="${CDATE:4:4}"
    [[ -z "$first_mmdd" ]] && first_mmdd="$mmdd"
    [[ "$mmdd" != "$first_mmdd" ]] && {
        echo "ERROR: CDATELIST MMDD mismatch"
        exit 1
    }
done

echo "All CDATEs have same MMDD: $first_mmdd"

CDATEARRAY=($CDATELIST)
CASE_NUM=${#CDATEARRAY[@]}

# ==========================================================
# Main Loop
# ==========================================================

iexp=0
for exp in $EXPLIST; do
((iexp++))

for i in "${!VARLIST[@]}"; do

    var=${VARLIST[$i]}
    VARANA=${VARLIST_OBS_FULLNAME[$i]}
    VARANA_TYPE=$(echo "${VARLIST_OBS_TYPE[$i]}" | tr '[:lower:]' '[:upper:]')

    echo "======================================="
    echo "Processing EXP=$exp VAR=$var OBS=$VARANA"
    echo "======================================="

    # --- Determine ANA file ---
    if [[ "$VARANA" != "none" ]]; then
        anafile=$(get_anafile "$VARANA_TYPE" "$VARANA")
        file_exists_or_exit "$anafile"
        echo "Using ANA file: $anafile"
    fi

    tmpdir="$WORKDIR/tmp.$var.$exp"
    rm -rf "$tmpdir"
    mkdir -p "$tmpdir"
    cd "$tmpdir"

# ----------------------------------------------------------
# 1. Reorganize by Lead Month
# ----------------------------------------------------------

for istep in $(seq 1 $Nmonth); do

    for CDATE in $CDATELIST; do

        year=${CDATE:0:4}
        month=${CDATE:4:2}
        day=${CDATE:6:2}
        hour=${CDATE:8:2}
        icdate=${CDATE:4:4}

        if [[ $NENS -gt 0 ]]; then
            filein="$exp.$CDATE.$var.mem0-$NENS.1p0.monthly.nc"
        else
            filein="$exp.$CDATE.$var.mem0.1p0.monthly.nc"
        fi

        infile="$DATAOUT/$var/$filein"
        file_exists_or_exit "$infile"

        outfile="$exp.$CDATE.$var.${icdate}.leadmon${istep}.nc"

        cdo seltimestep,$istep "$infile" "$outfile"
        reset_to_month_start "$outfile" "$outfile.tmp"
        mv "$outfile.tmp" "$outfile"

        # ----- Corresponding ANA -----
        if [[ "$VARANA" != "none" && $iexp -eq 1 ]]; then

            ((istep1=istep-1))
            newdate=$(date -d "$(date -d "${year}-${month}-${day} ${hour}:00" +%Y-%m-01) +${istep1} month" +%Y%m%d)

            newyear=${newdate:0:4}
            newmonth=${newdate:4:2}

            cdo -L -P 8 \
                selmon,$newmonth \
                -selyear,$newyear \
                -selvar,$VARANA \
                "$anafile" \
                "ANA.$CDATE.$var.$icdate.leadmon${istep}.nc"
        fi

    done

    # Merge forecast
    output="$exp.$icdate.${CASE_NUM}yr.$var.leadmon${istep}.nc"
    cdo mergetime "$exp".*.$var.$icdate.leadmon${istep}.nc \
        "$output"
    cdo setreftime,1980-01-01,00:00 -settunits,years $output $DATAOUT/$var/$output


    # Merge ANA
    if [[ "$VARANA" != "none" && $iexp -eq 1 ]]; then
        output="ANA.$icdate.${CASE_NUM}yr.$var.leadmon${istep}.nc"
        cdo mergetime ANA.*.$var.$icdate.leadmon${istep}.nc \
            $output
        cdo setreftime,1980-01-01,00:00 -settunits,years $output $DATAOUT/$var/$output
    fi

done

# ----------------------------------------------------------
# 2. Monthly Climatology & Anomaly
# ----------------------------------------------------------

for istep in $(seq 1 $Nmonth); do

    input="$DATAOUT/$var/$exp.$icdate.${CASE_NUM}yr.$var.leadmon${istep}.nc"
    prefix="$DATAOUT/$var/$exp.$icdate.climate.${CASE_NUM}yr.$var.leadmon${istep}"
    compute_climate_and_anom "$input" "$prefix"

    if [[ "$VARANA" != "none" && $iexp -eq 1 ]]; then
        input="$DATAOUT/$var/ANA.$icdate.${CASE_NUM}yr.$var.leadmon${istep}.nc"
        prefix="$DATAOUT/$var/ANA.$icdate.climate.${CASE_NUM}yr.$var.leadmon${istep}"
        compute_climate_and_anom "$input" "$prefix"
    fi

done

# ----------------------------------------------------------
# 3. Seasonal Means
# ----------------------------------------------------------

for range in 2-4 5-7 8-10 11-12; do
    compute_seasonal_mean "$DATAOUT/$var/$exp" "$icdate" "$CASE_NUM" "$var" "$range"

    if [[ "$VARANA" != "none" && $iexp -eq 1 ]]; then
        compute_seasonal_mean "$DATAOUT/$var/ANA" "$icdate" "$CASE_NUM" "$var" "$range"
    fi
done

done
done

echo "Processing complete."

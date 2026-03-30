#!/bin/bash


set -x

module load cdo
module load wgrib2

#######################################
# configuration
#######################################


GET_ENSSTAT=YES

pdy=${CDATE:0:8}
VARLIST="SSH SST speed MLD_003 MLD_0125 SSU SSV,ePBL latent sensible SW LW taux tauy temp so uo vo"
VARLIST="SST"

#######################################
# variable groups
#######################################



#######################################
# main variable loop
#######################################

for VAR in $VARLIST; do

mkdir -p $DATAOUT/$VAR

#######################################
# ensemble loop
#######################################

for m in $(seq 0 $((NENS))); do

member=$(printf "%03d" $m)

tmpdir=./tmpdir.ocn.$CDATE.$exp/$VAR.$member
mkdir -p $tmpdir

#######################################
# month loop
#######################################

for mon in $(seq 0 11); do

validyyyy=$(date -d "$pdy +$mon month" +%Y)
validmm=$(date -d "$pdy +$mon month" +%m)

file=$DATAIN/sfs.$pdy/00/mem${member}/products/ocean/netcdf/1p00/sfs.ocean.t$CDATE.1p00.monthly_avg.${validyyyy}-$validmm.nc

[[ -f $file ]] || continue


echo "find and reading $file ($VAR)"


cdo select,name=$VAR $file $tmpdir/${VAR}.${validyyyy}${validmm}.nc

done

#######################################
# output file
#######################################

outfile=$DATAOUT/$VAR/$exp.$CDATE.${VAR}.mem${m}.1p0.monthly.nc

#######################################
# daily → monthly mean
#######################################

rm -f $outfile
cdo mergetime $tmpdir/${VAR}.*.nc $outfile


echo "saved $outfile"

#rm -rf $tmpdir

done #loop member

#######################################
# ensemble statistics
#######################################
if [[ "$GET_ENSSTAT" == "YES" ]]; then

    files=$(printf "$DATAOUT/$VAR/$exp.$CDATE.${VAR}.mem%d.1p0.monthly.nc " $(seq 0 $NENS))

    all_exist=true
    for f in $files; do
        if [ ! -f "$f" ]; then
            echo "Missing file: $f"
            all_exist=false
            break
        fi
    done

    if $all_exist; then
        ensmean_out="$DATAOUT/$VAR/$exp.$CDATE.${VAR}.ensmean0-${NENS}.1p0.monthly.nc"
        ensstd_out="$DATAOUT/$VAR/$exp.$CDATE.${VAR}.ensstd0-${NENS}.1p0.monthly.nc"

        # Remove old outputs if they exist
        [ -f "$ensmean_out" ] && rm -f "$ensmean_out"
        [ -f "$ensstd_out" ] && rm -f "$ensstd_out"

        # Run calculations
        cdo ensmean $files "$ensmean_out"
        cdo ensstd  $files "$ensstd_out"

   else
        echo "ERROR: Not all input files exist. Skipping ensmean/ensstd."
    fi


fi

done #loop var

#!/bin/bash

set -x

module load cdo
module load wgrib2


#######################################
# configuration
#######################################
WORKDIR=$PWD
cd $WORKDIR

INTERPFLAG=YES  

pdy=${CDATE:0:8}

#######################################
# variable groups
#######################################

declare -A STREAM
declare -A DAILY

# acc monthly
#for v in APCP ACPCP NCPCP DLWRFSFC USWRFSFC ULWRFTOA; do
for v in APCP; do
STREAM[$v]="acc.monthly"
DAILY[$v]="NO"
done

# inst monthly
#for v in T2M U10M V10M; do
for v in T2M; do
STREAM[$v]="inst.monthly"
DAILY[$v]="NO"
done

# acc daily
#for v in TCDC DSWRFSFC DSWRFTOA USWRFTOA ULWRFSFC; do
#STREAM[$v]="acc.daily"
#DAILY[$v]="YES"
#done

# inst daily
#for v in PWAT CAPE; do
#STREAM[$v]="inst.daily"
#DAILY[$v]="YES"
#done

#######################################
# pattern mapping
#######################################

pattern(){

case $1 in
T2M) echo ":TMP:2 m above ground" ;;
U10M) echo "UGRD:10 m above ground" ;;
V10M) echo "VGRD:10 m above ground" ;;
DLWRFSFC) echo "DLWRF:surface" ;;
DSWRFTOA) echo "DSWRF:top of atmosphere" ;;
DSWRFTOA) echo "DSWRF:surface" ;;
USWRFSFC) echo "USWRF:surface" ;;
USWRFTOA) echo "USWRF:top of atmosphere" ;;
ULWRFSFC) echo "ULWRF:surface" ;;
ULWRFTOA) echo "ULWRF:top of atmosphere" ;;
*) echo "$1" ;;
esac

}

#######################################
# main variable loop
#######################################

for VAR in "${!STREAM[@]}"; do
	echo VAR=$VAR

stream=${STREAM[$VAR]}
isdaily=${DAILY[$VAR]}

mkdir -p $DATAOUT/$VAR

#######################################
# ensemble loop
#######################################

for m in $(seq 0 $((NENS))); do

member=$(printf "%03d" $m)

tmpdir=./tmpdir.$CDATE.$exp/$VAR.$member
rm -rf  $tmpdir
mkdir -p $tmpdir

#######################################
# month loop
#######################################

for mon in $(seq 0 11); do

validyyyymm=$(date -d "$pdy +$mon month" +%Y%m)

if [[ "$isdaily" == "YES" ]]; then
file=$DATAIN/sfs.$pdy/00/mem${member}/products/atmos/grib2/${stream}.mem${member}/${stream}.mem${member}.${pdy}00.${validyyyymm}.grib.t00z.grb2
else
file=$DATAIN/sfs.$pdy/00/mem${member}/products/atmos/grib2/${stream}.mem${member}/${stream}.${pdy}00.${validyyyymm}.grib.t00z.grb2
fi

if [ ! -f "$file" ]; then
         echo "Missing file: $file "
         all_exist=false
         break
	 
else

    pat=$(pattern $VAR)

    echo "reading $file ($VAR)"

    wgrib2 $file -match "$pat" -netcdf $tmpdir/${VAR}.${validyyyymm}.nc
fi

done

#######################################
# output file
#######################################

outfile_name=$exp.$CDATE.${VAR}.mem${m}.1p0.monthly.nc
outfile=$DATAOUT/$VAR/$outfile_name

#######################################
# daily → monthly mean
#######################################

if [[ "$isdaily" == "YES" ]]; then

cdo mergetime $tmpdir/${VAR}.*.nc $tmpdir/all.nc
cdo monmean $tmpdir/all.nc $tmpdir/$outfile_name

else

cdo mergetime $tmpdir/${VAR}.*.nc $tmpdir/$outfile_name

fi

if [ $INTERPFLAG == "YES"  ];then

cat <<EOF > $tmpdir/grid.txt
gridtype = lonlat
xsize    = 360
ysize    = 181
xfirst   = 0
xinc     = 1.
yfirst   = -90
yinc     = 1.0
xname    = longitude
yname    = latitude
EOF

rm -rf $outfile
cdo remapbil,grid.txt $tmpdir/$outfile_name $outfile
else
 mv $tmpdir/$outfile_name $outfile
fi
echo "saved $outfile"

rm -rf $tmpdir

done

#######################################
# ensemble statistics
#######################################

if [ "$NENS" -gt 0 ]; then
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

done

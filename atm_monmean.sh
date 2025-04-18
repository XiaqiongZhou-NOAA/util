source config.diag
rm -rf $WORKDIR
mkdir -p $WORKDIR
cd $WORKDIR
MACHINE=$(echo "$machine" | tr  '[:lower:]' '[:upper:]')

for EXP in $EXPLIST;do
  for i in "${!VARLIST[@]}"; do
    VAR=${VARLIST[$i]}
    VAR=$(echo "$VAR" | tr  '[:lower:]' '[:upper:]')

 	if [ $MACHINE = WCOSS2 ]; then

cat >job_${VAR}_${EXP}.sh <<EOF
#!/bin/bash
#PBS -j oe
#PBS -o ./out.$VAR.$EXP
#PBS -e ./out.$VAR.$EXP
#PBS -N transfer
#PBS -l walltime=06:00:00
##PBS -q "dev"
#PBS -A GFS-DEV
#PBS -l select=1:ncpus=1
module load intel-classic/2022.2.0.262 intel-oneapi/2022.2.0.262 intel/19.1.3.304
EOF
 	elif [ "$MACHINE" = "HERA" ]; then
cat >job_${VAR}_${EXP}.sh <<EOF
#!/bin/bash
#-----------------------------------------------------------
# Invoke as: sbatch $script
#-----------------------------------------------------------
#SBATCH --ntasks=1 --nodes=1
#SBATCH -t 6:30:00
#SBATCH -A fv3-cpu
#SBATCH -q batch
#SBATCH --partition=service
#SBATCH -J fv3
#SBATCH -o ./log.$VAR.$EXP
#SBATCH -e ./log.$VAR.$EXP
EOF
fi
cat <<EOF >> job_${VAR}_${EXP}.sh

module load wgrib2
module load cdo

export VAR=$VAR
export exp=$EXP
export DATADIR=$DATADIR
export FHMAX=$FHMAX
export INTV=$INTV
export CDATELIST="$CDATELIST"
export PRESLEV=$PRESLEV
export OUTPUTDIR=$OUTPUTDIR
export WORKDIR=$WORKDIR
mkdir -p \$OUTPUTDIR/\$VAR

var=\$VAR
case "$VAR" in
    UGRD|VGRD)
        var="(UGRD|VGRD)"
        ;;
    T2M)
        var="TMP:2 m above ground"
        ;;
    TS)
        var=":TMP:surface:"
        ;;
    TMAX2M)
        var="TMAX:2 m above ground"
        ;;
    TMIN2M)
        var="TMIN:2 m above ground"
        ;;
    T850)
        var="TMP:850 mb"
        ;;
    T200)
        var="TMP:200 mb"
        ;;
    RH200)
        var="RH:200 mb"
        ;;
    RH850)
        var="RH:850 mb"
        ;;
    U200)
	var="(UGRD:200 mb|VGRD:200 mb)"
        ;;
    U850)
	var="(UGRD:850 mb|VGRD:850 mb)"
        ;;
    U10M)
	var="(UGRD:10 m above ground|VGRD:10 m above ground)"
        ;;
    V10M)
	var="(UGRD:10 m above ground|VGRD:10 m above ground)"
        ;;
    WIND10M)
        var="WIND:10 m above ground"
        ;;
    DSWRFSFC)
        var=":DSWRF:surface:"
        ;;
    DLWRFSFC)
        var=":DLWRF:surface:"
        ;;
    USWRFSFC)
        var=":USWRF:surface:"
        ;;
    USWRFTOA)
        var=":USWRF:top of atmosphere:"
        ;;
    ULWRFTOA)
        var=":ULWRF:top of atmosphere:"
        ;;
    *)
        echo " variable: $VAR"
        ;;
esac


mkdir -p \$WORKDIR
cd \$WORKDIR
for CDATE in \$CDATELIST ;do
datadir=\$DATADIR/\$exp/\$CDATE/atmos/master/
rm -rf \$OUTPUTDIR/\$VAR/\$exp.\$CDATE.\${VAR}.1p0.grb2
rm -rf \$exp.\$CDATE.\${VAR}.grb2
          for ((ifhr=0; ifhr<=FHMAX; ifhr+=INTV)); do

            ((fhr=ifhr))
             if [ \$ifhr -lt 100 ];then
             fhr=\$(printf %03i \$ifhr)
             fi
	     filename=sfs.t00z.master.grb2f\$fhr

             wgrib2 \$datadir/\$filename -match "\${var}" -grib \$exp.\$CDATE.\${VAR}.grb2.tmp
             if [[ \${PRESLEV} == "YES" ]]; then

              wgrib2  \$exp.\$CDATE.\${VAR}.grb2.tmp -s |grep "mb" | wgrib2 -i  \$exp.\$CDATE.\${VAR}.grb2.tmp  -grib \$exp.\$CDATE.\${VAR}.grb2.tmp1
             cat \$exp.\$CDATE.\${VAR}.grb2.tmp1>>\$exp.\$CDATE.\${VAR}.grb2
             else
             cat \$exp.\$CDATE.\${VAR}.grb2.tmp>>\$exp.\$CDATE.\${VAR}.grb2
	     fi
      done

      wgrib2 \${exp}.\$CDATE.\${VAR}.grb2 -new_grid latlon 0:360:1.0 -90:181:1.0 \$OUTPUTDIR/\$VAR/\${exp}.\$CDATE.\${VAR}.1p0.grb2
          LEVELS=\$(wgrib2  \$exp.\$CDATE.\${VAR}.grb2.tmp1  -v | sort -u | wc -l)
          if [ \$VAR == "UGRD" -o  \$VAR == "VGRD" ];then
	      ((LEVELS=LEVELS/2))
          fi
          echo "Total vertical levels: \$LEVELS"

          wgrib2 \$OUTPUTDIR/\$VAR/\${exp}.\$CDATE.\${VAR}.1p0.grb2 -nc_nlev \$LEVELS -netcdf \${exp}.\$CDATE.\${VAR}.1p0.nc

      cdo monmean \${exp}.\$CDATE.\${VAR}.1p0.nc \$OUTPUTDIR/\$VAR/\${exp}.\$CDATE.\${VAR}.1p0.monthly.nc
      
echo \$CDATE
done
EOF
 	if [ $MACHINE = WCOSS2 ]; then
qsub $WORKDIR/job_${VAR}_${EXP}.sh
else
sbatch job_${VAR}_${EXP}.sh
fi
done
done


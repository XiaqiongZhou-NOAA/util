source config
mkdir -p $WORKDIR
for EXP in $EXPLIST;do
	for VAR in $VARLIST;do
cat >job_$VAR_$EXP.sh <<EOF
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
module load wgrib2/2.0.8
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
if [ \$VAR == "UGRD" -o  \$VAR == "VGRD" ];then
	var="(UGRD|VGRD)"
fi

mkdir -p \$WORKDIR
cd \$WORKDIR
for CDATE in \$CDATELIST ;do
datadir=\$DATADIR/\$exp/\$CDATE/atmos/master/
workdir=\$WORKDIR/tmp_\$CDATE_\$VAR
rm -rf \$OUTPUTDIR/\$VAR/\$exp.\$CDATE.\${VAR}.grb2
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
qsub job_$VAR_$EXP.sh
done
done


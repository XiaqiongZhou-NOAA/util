source config.diag
WORKDIR=${WORKDIR}_OCN
rm -rf ${WORKDIR}
mkdir -p ${WORKDIR}
cd $WORKDIR
MACHINE=$(echo "$machine" | tr  '[:lower:]' '[:upper:]')

for EXP in $EXPLIST;do
  for i in "${!VARLIST_OCN[@]}"; do
    VAR=${VARLIST_OCN[$i]}
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

mkdir -p \$WORKDIR
cd \$WORKDIR
for CDATE in \$CDATELIST ;do
datadir=\$DATADIR/\$exp/\$CDATE/ocean/history/
mkdir tmp_\$exp.\$CDATE.\${var}
          for ((ifhr=0; ifhr<=FHMAX; ifhr+=INTV)); do

            ((fhr=ifhr))
             if [ \$ifhr -lt 100 ];then
             fhr=\$(printf %03i \$ifhr)
             fi
	     filename=sfs.ocean.t00z.${INTV}hr_avg.f\${fhr}.nc
             cdo select,name=\$var \$datadir/\$filename tmp_\$exp.\$CDATE.\${var}/\$exp.\$CDATE.\${var}.f\${fhr}.nc
         done
          mkdir -p \$OUTPUTDIR/\$var
          
          cdo mergetime tmp_\$exp.\$CDATE.\$var/\$exp.\$CDATE.\$var.f*.nc \$exp.\$CDATE.\${var}.nc
          cdo monmean  \$exp.\$CDATE.\${var}.nc  \$OUTPUTDIR/\$var/\$exp.\$CDATE.\${var}.monthly.nc
          cdo remapbil,r360x181 \$OUTPUTDIR/\$var/\$exp.\$CDATE.\${var}.monthly.nc  \$OUTPUTDIR\/\$var/\$exp.\$CDATE.\${var}.1p0.monthly.nc

      
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


#!/bin/bash
#-----------------------------------------------------------
#SBATCH --ntasks=1 --nodes=1
#SBATCH -t 6:30:00
#SBATCH -A fv3-cpu
#SBATCH -q batch
#SBATCH -J fv3
#SBATCH -o ./log.plotam
#SBATCH -e ./log.plotam

module load grads
ulimit -c unlimited

CURR_DIR=$(pwd)
cd $CURR_DIR
source config.diag
mkdir -p tmp
cd tmp
cp -pr $SLURM../grads-scripts  .
echo $lenexp
if [ -z "$LEADMON" ]; then
    # Create a space-separated list from 1 to Nmonth
    LEADMON=$(seq -s ' ' 1 "$Nmonth")
fi
CDATELIST="${CDATELIST[*]}"
lenexp=$(echo $EXPLIST | wc -w)
lenmon=$(echo $LEADMON | wc -w)
(( nplots = lenexp*2 + 1 ))
echo $CDATELIST
echo $lecmon

for CDATE in $CDATELIST; do
  for i in "${!VARLIST[@]}"; do
    VAR=${VARLIST[$i]}
    VARANA=${VARLIST_OBS[$i]}
    LEVS=$LEVS
    LEVE=$LEVE
    echo $LEVS
    VAR=$(echo "$VAR" | tr  '[:lower:]' '[:upper:]')


    echo "Model variable: $VAR"
    echo "ERA variable:   $VARANA"
echo $VAR ' ' plot_${VAR}_${CDATE}.gs
cat >plot_${VAR}_${CDATE}.gs <<EOF
EXPLIST="$EXPLIST"
CDATE=$CDATE
VAR=$VAR
VARA='$VARANA'
VARA_name="$VARANA"
Nmonth=$Nmonth
lenmon=$lenmon
LEADMON="$LEADMON"
cmap_field="$cmap_field"
cmap_diff="$cmap_diff"
levs="$LEVS"
leve="$LEVE"
t=1
lenexp=$lenexp
nplots=$nplots
if ( VARA ='none')
nplots=lenexp+1
endif
while(t<=lenmon)
mon=subwrd(LEADMON,t)
tt=t-1
iexp=1
while (iexp<=lenexp)
exp.iexp=subwrd(EXPLIST,iexp)
exp=subwrd(EXPLIST,iexp)
'sdfopen  $DATAOUT/'VAR'/'exp.iexp'.'CDATE'.'VAR'.1p0.monthly.nc'
'set t 't
*'set dfile 'iexp
'q time'
say result
ctime=subwrd(result,3)
mm=substr(ctime,6,3)
yyyy=substr(ctime,9,42)
say mm
say yyyy
'q file'
say result
if ( VAR !='V10M' & VAR != 'V200' )
res=sublin(result,7)
else
res=sublin(result,8)
endif
say res
varname=subwrd(res,1)
say varname
'set lev 'levs' 'leve
'set lon 0'
'define fcst'iexp'=ave('varname'.'iexp',lon=0,lon=360)'
*if (iexp = 1)
*'close 1'
*endif
iexp=iexp+1
endwhile
if ( VARA !='none')
'sdfopen $ANADATADIR/ERA5_3D/'VARA_name'.1994-2024.mon.1p0.nc'
'set dfile 'iexp
'set time 01'mm''yyyy
'set lev 'levs' 'leve
'set lon 0'
'define ana=ave('VARA_name'.'iexp',lon=0,lon=360)'
endif
say result

iexp=1
while(iexp<=lenexp)
'$GRADSDIR/subplot.gs 'nplots'  'iexp
'set gxout shaded'
'set grads off'
'set grid off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
if (iexp = 1)
'set stat on'
'set zlog on'
'd fcst'iexp
say result
range=sublin(result,9)
cmin=subwrd(range,5)
cmax=subwrd(range,6)
cint=subwrd(range,7)
cint=cint/2
'set stat off'
endif
'$GRADSDIR/color.gs -kind 'cmap_field' 'cmin' 'cmax' 'cint
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'set zlog on'
'd fcst'iexp

*'d aave(fcst1,g)'
say result
ress=subwrd(result,4)
res=substr(ress,1,10)
'draw ylab Vertical'
'draw title 'exp.iexp' 'VAR'\'mm' 'yyyy
iexp=iexp+1
endwhile

**plot ERA5
if ( VARA !='none')
'$GRADSDIR/subplot.gs 'nplots'  'iexp
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'$GRADSDIR/color.gs -kind 'cmap_field' 'cmin' 'cmax' 'cint
'set zlog on'
'd ana'
'draw ylab Vertical'
*'d aave(fcst2,g)'
say result
ress=subwrd(result,4)
res=substr(ress,1,10)
'draw title ERA5 'VARA'\'mm' 'yyyy
endif
'$GRADSDIR/cbarm.gs 1 0 1'

iexp=1
while(iexp<=lenexp)
nexp=lenexp+iexp+1
'$GRADSDIR/subplot.gs 'nplots'  'nexp
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'$GRADSDIR/color.gs -kind 'cmap_field' 'cmin' 'cmax' 'cint
'set time  1'mm''yyyy
'set lev 'levs' 'leve
'set lon 0'
'set zlog on'
'set stat on'
if(iexp=1)
'd fcst'iexp'-ana'
say result
range=sublin(result,9)
cmin=subwrd(range,5)
cmax=subwrd(range,6)
cint=subwrd(range,7)
cint=cint/2
if (math_abs(cmin)>math_abs(cmax))
cmax=math_abs(cmin)
else
cmin=-1*cmax
endif
'set stat off'
endif
'$GRADSDIR/color.gs -kind 'cmap_diff' 'cmin' 'cmax' 'cint
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'set zlog on'
'd fcst'iexp'-ana'
'draw ylab Vertical'
*'d aave(fcst2-fcst1,g)'
say result
ress=subwrd(result,4)
res=substr(ress,1,10)

'draw title 'exp.iexp'-ERA5 'VAR' DIFF\'mm' 'yyyy
iexp=iexp+1
endwhile

'$GRADSDIR/cbarm.gs 1 0 1'
'printim 'exp'.diff_'VAR'_'CDATE'_leadmonth'mon'.png x1000 y1000  white'
'close 1'
t=t+1
*pull dummy
*'c'
reinit
endwhile
'quit'
EOF
grads -blc "run  plot_${VAR}_${CDATE}.gs"
done
done


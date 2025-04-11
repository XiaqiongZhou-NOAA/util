source config.diag
module load netcdf
mkdir -p tmp
cd tmp
lenexp=${#EXPLIST[@]}
echo $lenexp

for CDATE in $CDATELIST; do
  for i in "${!VARLIST[@]}"; do
    VAR=${VARLIST[$i]}
    VARANA=${VARLIST_ERA[$i]}
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
cmap_field="$cmap_field"
cmap_diff="$cmap_diff"
t=1
lenexp=$lenexp
while(t<=Nmonth)
tt=t-1
iexp=1
while (iexp<=2)
exp.iexp=subwrd(EXPLIST,iexp)
exp=subwrd(EXPLIST,iexp)
'sdfopen  $OUTPUTDIR/'VAR'/'exp.iexp'.'CDATE'.'VAR'.1p0.monthly.nc'
'set t 't
'q time'
say result
ctime=subwrd(result,3)
mm=substr(ctime,6,3)
yyyy=substr(ctime,9,42)
say mm
say yyyy
'q file'
say result
res=sublin(result,7)
say res
varname=subwrd(res,1)
say varname
'define fcst'iexp'='varname'.'iexp
iexp=iexp+1
endwhile
if ( VARA !='none')
'sdfopen $ERADIR/ERA5.1994-2020.monthly.2dvars.1p0.nc'
'set dfile 'iexp
'set time 00Z01'mm''yyyy
'define ana='VARA_name
endif
say result
'$GRADSDIR/subplot.gs 4  1'
'set gxout shaded'
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'set stat on'
'd fcst1'
say result
range=sublin(result,9)
cmin=subwrd(range,5)
cmax=subwrd(range,6)
cint=subwrd(range,7)
cint=cint/2

'set stat off'
*'$GRADSDIR/colormaps.gs -map 'cmap_field'  'flipped_field' -levels 'cmin' 'cmax' 'cint
'$GRADSDIR/color.gs -kind 'cmap_field' 'cmin' 'cmax' 'cint
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'd fcst1'
'd aave(fcst1,g)'
say result
ress=subwrd(result,4)
res=substr(ress,1,10)
*'$GRADSDIR/cbarm.gs'
'draw title 'exp.1' 'VAR' mean='res' \ 'mm' 'yyyy

'$GRADSDIR/subplot.gs 4  2'
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'$GRADSDIR/color.gs -kind 'cmap_field' 'cmin' 'cmax' 'cint
'd fcst2'
'd aave(fcst2,g)'
say result
ress=subwrd(result,4)
res=substr(ress,1,10)
'$GRADSDIR/cbarm.gs'
'draw title 'exp.2' 'VAR' mean='res'\ 'mm' 'yyyy

'$GRADSDIR/subplot.gs 4  3'
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'$GRADSDIR/color.gs -kind 'cmap_field' 'cmin' 'cmax' 'cint
'd ana'
'd aave(fcst2,g)'
say result
ress=subwrd(result,4)
res=substr(ress,1,10)
'$GRADSDIR/cbarm.gs'
'draw title ANA 'VARA' mean='res'\ 'mm' 'yyyy

'$GRADSDIR/subplot.gs 4  4'
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'set stat on'
'd fcst2-fcst1'
say result
range=sublin(result,9)
cmin=subwrd(range,5)
cmax=subwrd(range,6)
cint=subwrd(range,7)
cint=cint/2
'set stat off'
'$GRADSDIR/color.gs -kind 'cmap_diff' 'cmin' 'cmax' 'cint
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'd fcst2-fcst1'
'd aave(fcst2-fcst1,g)'
say result
ress=subwrd(result,4)
res=substr(ress,1,10)

'$GRADSDIR/cbarm.gs'
'draw title 'exp.2'-'exp.1' 'VAR' DIFF mean='res' \ 'mm' 'yyyy
'printim 'exp'.diff_'VAR'_'CDATE'_leadmonth'tt'.png x1000 y1000  white'
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


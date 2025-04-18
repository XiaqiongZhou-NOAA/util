source config.diag
module load netcdf
mkdir -p tmp
cd tmp
lenexp=${#EXPLIST[@]}
(( nplots = lenexp + 2 ))
echo $lenexp

for CDATE in $CDATELIST; do
  for i in "${!VARLIST_OCN[@]}"; do
    VAR=${VARLIST_OCN[$i]}
    VARANA=${VARLIST_CERES[$i]}
    VAR=$(echo "$VAR" | tr  '[:lower:]' '[:upper:]')
    if [ "$VAR" = "SST" ]; then
	   anafile=$OISSTDIR/$OISSTFILENAME
           VARANA=sst
    else 
	    anafile=$CERESDIR/$CERESFILENAME

    fi	    

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
nplots=$nplots
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
if ( VAR !='V10M' & VAR != 'V200' )
res=sublin(result,7)
else
res=sublin(result,8)
endif
say res
varname=subwrd(res,1)
say varname
'define fcst'iexp'='varname'.'iexp
iexp=iexp+1
endwhile
if ( VARA !='none')
'sdfopen $anafile'
'set dfile 'iexp
'set time 00Z01'mm''yyyy
'define ana='VARA_name
endif
say result
'$GRADSDIR/subplot.gs 'nplots'  1 '
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
'$GRADSDIR/cbarm.gs 1 0 1'
'draw title 'exp.1' 'VAR' \ mean='res' 'mm' 'yyyy

'$GRADSDIR/subplot.gs 'nplots'  2 '
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
if (math_abs(cmin)>math_abs(cmax))
cmax=math_abs(cmin)
else
cmin=-1*cmax
endif
if ( VAR = 'SST' )
cmin=-4
cmax=4
cint=0.5
endif
'set stat off'
'$GRADSDIR/color.gs -kind 'cmap_diff' 'cmin' 'cmax' 'cint
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'd fcst2-ana'
'd aave(fcst2-ana,g)'
say result
ress=subwrd(result,4)
res=substr(ress,1,10)
'$GRADSDIR/cbarm.gs 1 0 1'
'draw title 'exp.2' 'VAR' bias\ mean='res' 'mm' 'yyyy

'$GRADSDIR/subplot.gs 'nplots'  3 '
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'$GRADSDIR/color.gs -kind 'cmap_diff' 'cmin' 'cmax' 'cint
'd fcst1-ana'
'd aave(fcst1-ana,g)'
say result
ress=subwrd(result,4)
res=substr(ress,1,10)
'$GRADSDIR/cbarm.gs 1 0 1'
'draw title 'exp.1' 'VAR' bias\ mean='res' 'mm' 'yyyy

'$GRADSDIR/subplot.gs 'nplots'  4 '
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
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

'$GRADSDIR/cbarm.gs 1 0 1'
'draw title 'exp.2'-'exp.1' 'VAR' DIFF\ mean='res' 'mm' 'yyyy



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


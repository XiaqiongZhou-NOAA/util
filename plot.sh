source config.diag
module load netcdf
mkdir -p $WORKDIR
lenexp=${#EXPLIST[@]}
echo $lenexp
for CDATE in $CDATELIST; do
	for VAR in $VARLIST; do
echo $VAR ' ' plot_${VAR}_${CDATE}.gs
cat >plot_${VAR}_${CDATE}.gs <<EOF
EXPLIST="$EXPLIST"
CDATE=$CDATE
VAR=$VAR
Nmonth=$Nmonth
cmap_field=$cmap_field
cmap_diff=$cmap_diff
flipped_field="$flipped_field"
flipped_diff="$flipped_diff"
t=1
lenexp=$lenexp
while(t<=Nmonth)
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
say result
'set grid off'
'set grads off'
'set lat -90 90'
'set gxout shaded'
'$GRADSDIR/subplot.gs 4  1'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'set stat on'
'd fcst1'
say result
range=sublin(result,9)
cmin=subwrd(range,5)
cmax=subwrd(range,6)
cint=subwrd(range,7)

'$GRADSDIR/colormaps.gs -map 'cmap_field'  'flipped' -levels 'cmin' 'cmax' 'cint
'set grid off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'set grads off'
'd fcst1'
'$GRADSDIR/cbarm.gs'
'draw title 'exp.1' 'VAR'  'mm' 'yyyy

'$GRADSDIR/subplot.gs 4  2'
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'$GRADSDIR/colormaps.gs -map 'cmap_field'  'flipped' -levels 'cmin' 'cmax' 'cint
'd fcst2'
'$GRADSDIR/cbarm.gs'
'draw title 'exp.2' 'VAR'  'mm' 'yyyy
'$GRADSDIR/subplot.gs 4  3'
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'd fcst1-fcst2'
say result
range=sublin(result,9)
cmin=subwrd(range,5)
cmax=subwrd(range,6)
cint=subwrd(range,7)
'$GRADSDIR/colormaps.gs -map 'cmap_diff'  'flipped' -levels 'cmin' 'cmax' 'cint
'set grid off'
'set grads off'
'set xlopts 1 6 0.15'
'set ylopts 1 6 0.15'
'd fcst1-fcst2'
'$GRADSDIR/cbarm.gs'
'draw title 'exp.1'-'exp.2' 'VAR' DIFF 'mm' 'yyyy
'printim 'exp'.diff_'VAR'_'mm''yyyy'.png x1000 y1000  white'
'close 1'
t=t+1
*pull dummy
*'c'
reinit
endwhile
'quit'
EOF
grads -bpc "run  plot_${VAR}_${CDATE}.gs"
done
done


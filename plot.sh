source config
mkdir -p $WORKDIR
export VARLIST="APCP ACPCP NCPCP TCOLW TCOLI TCOLS TCOLS TCOLC LCDC MCDC HCDC TCDC"
EXPLIST="c96n c96n_tte"
lenexp=${#EXPLIST[@]}
export CDATELIST="2012050100 2012110100"
echo $lenexp
for CDATE in $CDATELIST; do
	for VAR in $VARLIST; do
echo $VAR ' ' plot_${VAR}_${CDATE}.gs
cat >plot_${VAR}_${CDATE}.gs <<EOF
EXPLIST="$EXPLIST"
CDATE=$CDATE
VAR=$VAR
t=1
lenexp=$lenexp
while(t<5)
iexp=1
while (iexp<=2)
exp=subwrd(EXPLIST,iexp)
'sdfopen  data/'VAR'/'exp'.'CDATE'.'VAR'.1p0.monthly.nc'
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
*'/lfs/h2/emc/global/noscrub/xiaqiong.zhou/util/grads/gscript/color.gs -levs -4 -3 -2 -1 -0.5 -0.3 0.3 0.5 1 2 3 4  -kind blue2red1'
'/lfs/h2/emc/global/noscrub/xiaqiong.zhou/util/grads/grads-scripts/subplot.gs 4  1'

'd fcst1'
'/lfs/h2/emc/global/noscrub/xiaqiong.zhou/util/grads/grads-scripts/subplot.gs 4  2'
'set grid off'
'set grads off'
'd fcst2'
'/lfs/h2/emc/global/noscrub/xiaqiong.zhou/util/grads/grads-scripts/subplot.gs 4  3'
'set grid off'
'set grads off'
'd fcst1-fcst2'
'/lfs/h2/emc/global/noscrub/xiaqiong.zhou/util/grads/gscript/xcbar.gs 3 8 0.8 1.0'
'draw title 'exp' SST bias 'mm' 'yyyy
'printim 'exp'.bias_sst_'mm'.png x1000 y1000  white'
'close 1'
t=t+1
pull dummy
'c'
reinit
endwhile
EOF
#*grads job_$VAR_$EXP.sh
done
done


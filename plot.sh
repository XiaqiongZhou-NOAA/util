#!/bin/bash
#-----------------------------------------------------------
# Invoke as: sbatch $script
#-----------------------------------------------------------
#SBATCH --ntasks=1 --nodes=1
#SBATCH -t 6:30:00
#SBATCH -A fv3-cpu
#SBATCH -q batch
#SBATCH -J fv3
#SBATCH -o ./log
#SBATCH -e ./log
current_dir=$PWD
cd $current_dir
source config.diag.20260301
mkdir -p tmp
cd tmp
cp -pr ../grads-scripts/ .
lenexp=$(echo $EXPLIST | wc -w)
CDATEARRAY=($CDATELIST)
CASE_NUM=${#CDATEARRAY[@]}

CDATELIST="${CDATELIST[*]}"
echo $CDATELIST
echo $lenexp

    plot_monmean=$(echo "$plot_monmean" | tr  '[:lower:]' '[:upper:]')
    plot_diff=$(echo "$plot_diff" | tr  '[:lower:]' '[:upper:]')
for CDATE in $CDATELIST; do
  for i in "${!VARLIST[@]}"; do
    VAR=${VARLIST[$i]}
#    VAR=$(echo "$VAR" | tr  '[:lower:]' '[:upper:]')
    VARANA=${VARLIST_OBS[$i]}
    VARANA_TYPE=${VARLIST_OBS_TYPE[$i]}
    VARANA_TYPE=$(echo "$VARANA_TYPE" | tr  '[:lower:]' '[:upper:]')
    if echo "$CDATE" | grep -qi "climate"; then
    echo "Plotting case mean state'"
    plot_casemean="YES"
    else
    plot_casemean="NO"
    echo "Plotting individual case'"
      if [ "$VARANA_TYPE" = "OISST" ]; then
	   anafile=$ANADATADIR/$OISSTFILENAME
      elif [ "$VARANA_TYPE" = "CERES_CLD" ]; then
	    anafile=$ANADATADIR/$CERESFILENAME_CLD
      elif [ "$VARANA_TYPE" = "CERES" ]; then
	    anafile=$ANADATADIR/$CERESFILENAME
      elif [ "$VARANA_TYPE" = "CERES_SFC" ]; then
	    anafile=$ANADATADIR/$CERESFILENAME_SFC
      elif [ "$VARANA_TYPE" = "ERA5_3D" ]; then
           anafile=$ANADATADIR/ERA5_3D/$VARANA.1994-2024.mon.1p0.nc
      else
           anafile=$ANADATADIR/$ERAFILENAME
      fi	    
    echo "Model variable: $VAR"
    echo "OBS variable:   $VARANA"
    echo "Reference file: $anafile"
    fi


echo $VAR ' ' plot_${VAR}_${CDATE}.gs
cat >plot_${VAR}_${CDATE}.gs <<EOF
EXPLIST="$EXPLIST"
CDATE=$CDATE
VAR=$VAR
VARA='$VARANA'
VARA_name='$VARANA'
VARANA_TYPE='$VARANA_TYPE'
plot_monmean='$plot_monmean'
plot_diff='$plot_diff'
plot_casemean='$plot_casemean'
Nmonth=$Nmonth
PRESLEV='$PRESLEV'
LEVS=$LEVS
lats=$lats
late=$late
lons=$lons
lone=$lone
cmap_field="$cmap_field"
cmap_diff="$cmap_diff"
cmap_bias="$cmap_bias"
nmem=$NENS
t=Nmonth
lenexp=$lenexp
nplots=lenexp*3
if ( VARA = 'none')
  nplots=lenexp*2
  plot_monmean='YES'
  plot_diff='YES'
else
  if (plot_monmean!='YES')
     nplots=lenexp*2-1
  endif
endif
while(t>=1)
 tt=t-1
 iexp=1
**get fcst monthly mean
   while (iexp<=lenexp)
      exp.iexp=subwrd(EXPLIST,iexp)
      exp=subwrd(EXPLIST,iexp)
      if (nmem>0)
         'sdfopen  $DATAOUT/'VAR'/'exp.iexp'.'CDATE'.'VAR'.ensmean0-'nmem'.1p0.monthly.nc'
      else
         'sdfopen  $DATAOUT/'VAR'/'exp.iexp'.'CDATE'.'VAR'.mem0.1p0.monthly.nc'
      endif
     'set t 't
      'set lat 'lats' 'late
      'set lon 'lons' 'lone
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
      if (PRESLEV='YES')
        'set lev 'LEVS
      endif
      'define fcst'iexp'='varname
      iexp=iexp+1
      'close 1'
   endwhile

** get OBS monthly mean
   if ( VARA !='none')
      if ( plot_casemean = 'YES' )
	 anafile='$DATAOUT/'VAR'/ANA.'CDATE'.'VAR'.1p0.monthly.nc'
      else
        'sdfopen $anafile'
        'set time 'mm''yyyy
        'set lat 'lats' 'late
        'set lon 'lons' 'lone
        'define ana='VARA_name
      endif
    else
        if (nmem>0)
         'sdfopen  $DATAOUT/'VAR'/'exp.1'.'CDATE'.'VAR'.ensmean0-'nmem'.1p0.monthly.nc'
        else
         'sdfopen  $DATAOUT/'VAR'/'exp.1'.'CDATE'.'VAR'.mem0.1p0.monthly.nc'
        endif
   endif
   say result

** plot monthly mean
   iexp=1
   nplot=iexp
      'set lat 'lats' 'late
      'set lon 'lons' 'lone
   if( plot_monmean = 'YES') 
      while(iexp<=lenexp)
         '$GRADSDIR/subplot.gs 'nplots'  'nplot
         'set gxout shaded'
         'set grid off'
         'set grads off'
         'set xlopts 1 6 0.15'
         'set ylopts 1 6 0.15'
      'set lat 'lats' 'late
      'set lon 'lons' 'lone
      if (PRESLEV='YES')
        'set lev 'LEVS
      endif
          if(iexp=1 & t=Nmonth)
              'set stat on'
               'd fcst'iexp
                say result
                range=sublin(result,9)
                cminf=subwrd(range,5)
                cmaxf=subwrd(range,6)
                cintf=subwrd(range,7)
                cintf=cintf/2
                'set stat off'
           endif

           '$GRADSDIR/color.gs -kind 'cmap_field' 'cminf' 'cmaxf' 'cintf
           'set grid off'
           'set grads off'
           'set xlopts 1 6 0.15'
           'set ylopts 1 6 0.15'
           'd fcst'iexp
           'd aave(fcst'iexp',g)'
            say result
            ress=subwrd(result,4)
            res=substr(ress,1,15)
            'draw title 'exp.iexp' 'VAR' \ mean='res' 'mm' 'yyyy' NENS='nmem
            '$GRADSDIR/cbarm.gs 1 0 1'
            iexp=iexp+1
            nplot=nplot+1
     endwhile
   endif
     if ( VARA !='none')
** plot OBS monthly mean
          if( plot_monmean = 'YES') 
            '$GRADSDIR/subplot.gs 'nplots'  'nplot
            'set grid off'
            'set grads off'
            'set xlopts 1 6 0.15'
            'set ylopts 1 6 0.15'
      if (PRESLEV='YES')
        'set lev 'LEVS
      endif
            '$GRADSDIR/color.gs -kind 'cmap_field' 'cminf' 'cmaxf' 'cintf
            'd ana'
            'd aave(ana,g)'
            ress=subwrd(result,4)
            res=substr(ress,1,15)
            'draw title 'VARANA_TYPE' 'VARA' \ mean='res' 'mm' 'yyyy
            '$GRADSDIR/cbarm.gs 1 0 1'
            nplot=nplot+1
         endif

** plot fcst bias
         iexp=1
         while(iexp<=lenexp)
             '$GRADSDIR/subplot.gs 'nplots'  'nplot
              if(iexp=1 & t=Nmonth)
                 'set stat on'
                 'set grid off'
                 'set grads off'
                 'set xlopts 1 6 0.15'
                 'set ylopts 1 6 0.15'
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
                 if ( VAR = 'SST' )
                    cmin=-4
                    cmax=4
                    cint=0.5
                 endif
                 'set stat off'
             endif
             '$GRADSDIR/color.gs -kind 'cmap_diff' 'cmin' 'cmax' 'cint
             'set grid off'
             'set grads off'
             'set xlopts 1 6 0.15'
             'set ylopts 1 6 0.15'
              'd fcst'iexp'-ana'
             'd aave(fcst'iexp'-ana,g)'
             say result
             ress=subwrd(result,4)
             res=substr(ress,1,15)
            '$GRADSDIR/cbarm.gs 1 0 1'
             'draw title 'exp.iexp' 'VAR' bias against 'VARANA_TYPE'\ mean='res' 'mm' 'yyyy' NENS='nmem
             iexp=iexp+1
             nplot=nplot+1
         endwhile
     endif
** plot difference between experiments
    if (lenexp>=2 & plot_diff='YES' )
       iexp=2
       while(iexp<=lenexp )
       '$GRADSDIR/subplot.gs 'nplots'  'nplot
         if(iexp=2 & VARA='none' & t=Nmonth )
           'set stat on'
           'set grid off'
           'set grads off'
           'set xlopts 1 6 0.15'
           'set ylopts 1 6 0.15'
           'd fcst'iexp'-fcst1'
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
        endif
       'set grid off'
       'set grads off'
       'set xlopts 1 6 0.15'
       'set ylopts 1 6 0.15'
       '$GRADSDIR/color.gs -kind 'cmap_diff' 'cmin' 'cmax' 'cint
       'd fcst'iexp'-fcst1'
       'd aave(fcst'iexp'-fcst1,g)'
        say result
        ress=subwrd(result,4)
        res=substr(ress,1,10)
       '$GRADSDIR/cbarm.gs 1 0 1'
       'draw title 'exp.iexp'-'exp.1' 'VAR' diff\ mean='res' 'mm' 'yyyy' NENS='nmem
        iexp=iexp+1
        nplot=nplot+1
      endwhile
    endif

if (PRESLEV='YES')
   'printim 'exp'.diff_'VAR''LEVS'_'CDATE'_leadmonth'tt'.png x1000 y1000  white'
else
   'printim 'exp'.diff_'VAR'_'CDATE'_leadmonth'tt'.png x1000 y1000  white'
endif
'close 1'
t=t-1
*pull dummy
*'c'
reinit
endwhile
'quit'
EOF
grads -pblc "run  plot_${VAR}_${CDATE}.gs"
done
done


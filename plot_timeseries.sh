source config.diag
mkdir -p tmp
cd tmp
cp -pr ../grads-scripts/ .
lenexp=$(echo $EXPLIST | wc -w)
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
    if [ "$VARANA_TYPE" = "OISST" ]; then
	   anafile=$ANADATADIR/$OISSTFILENAME
    elif [ "$VARANA_TYPE" = "CERES_CLD" ]; then
	    anafile=$ANADATADIR/$CERESFILENAME_CLD
    elif [ "$VARANA_TYPE" = "CERES" ]; then
	    anafile=$ANADATADIR/$CERESFILENAME
    elif [ "$VARANA_TYPE" = "CERES_SFC" ]; then
	    anafile=$ANADATADIR/$CERESFILENAME_SFC
    else
           anafile=$ANADATADIR/$ERAFILENAME
    fi	    
    echo "Model variable: $VAR"
    echo "OBS variable:   $VARANA"
    echo "Reference file: $anafile"

# generate 2dmaps GrADS scripts
echo $VAR ' ' plot_${VAR}_${CDATE}.gs
if [ "$plot_2dmaps" = "YES" ]; then
cat >plot_${VAR}_${CDATE}.gs <<EOF
EXPLIST="$EXPLIST"
CDATE=$CDATE
VAR=$VAR
VARA='$VARANA'
VARA_name='$VARANA'
VARANA_TYPE='$VARANA_TYPE'
plot_monmean='$plot_monmean'
plot_diff='$plot_diff'
Nmonth=$Nmonth
PRESLEV='$PRESLEV'
LEVS=$LEVS
cmap_field="$cmap_field"
cmap_diff="$cmap_diff"
cmap_bias="$cmap_bias"
nmem=$NENS
t=1
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
while(t<=Nmonth)
 tt=t-1
 iexp=1
**get fcst monthly mean
   while (iexp<=lenexp)
      exp.iexp=subwrd(EXPLIST,iexp)
      exp=subwrd(EXPLIST,iexp)
      if (nmem>0)
         'sdfopen  $DATAOUT/'VAR'/'exp.iexp'.'CDATE'.'VAR'.mem0-'nmem'.1p0.monthly.nc'
      else
         'sdfopen  $DATAOUT/'VAR'/'exp.iexp'.'CDATE'.'VAR'.mem0.1p0.monthly.nc'
      endif
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
      if (PRESLEV='YES')
        'set lev 'LEVS
      endif
      'define fcst'iexp'='varname
      iexp=iexp+1
      'close 1'
   endwhile

** get OBS monthly mean
   if ( VARA !='none')
      'sdfopen $anafile'
      'set time 'mm''yyyy
      'define ana='VARA_name
   else
      if (nmem>0)
         'sdfopen  $DATAOUT/'VAR'/'exp.1'.'CDATE'.'VAR'.mem0-'nmem'.1p0.monthly.nc'
      else
         'sdfopen  $DATAOUT/'VAR'/'exp.1'.'CDATE'.'VAR'.mem0.1p0.monthly.nc'
      endif
   endif
   say result

** plot monthly mean
   iexp=1
   nplot=iexp
   if( plot_monmean = 'YES') 
      while(iexp<=lenexp)
         '$GRADSDIR/subplot.gs 'nplots'  'nplot
         'set gxout shaded'
         'set grid off'
         'set grads off'
         'set xlopts 1 6 0.15'
         'set ylopts 1 6 0.15'
          if(iexp=1)
              'set stat on'
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
           'd fcst'iexp
           'd aave(fcst'iexp',g)'
            say result
            ress=subwrd(result,4)
            res=substr(ress,1,10)
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
            '$GRADSDIR/color.gs -kind 'cmap_field' 'cmin' 'cmax' 'cint
            'd ana'
            'd aave(ana,g)'
            ress=subwrd(result,4)
            res=substr(ress,1,10)
            'draw title 'VARANA_TYPE' 'VARA' \ mean='res' 'mm' 'yyyy
            '$GRADSDIR/cbarm.gs 1 0 1'
            nplot=nplot+1
         endif

** plot fcst bias
         iexp=1
         while(iexp<=lenexp)
             '$GRADSDIR/subplot.gs 'nplots'  'nplot
              if(iexp=1)
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
             res=substr(ress,1,10)
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
         if(iexp=2 & VARA='none')
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

'printim 'exp'.diff_'VAR'_'CDATE'_leadmonth'tt'.png x1000 y1000  white'
'close 1'
t=t+1
*pull dummy
*'c'
reinit
endwhile
'quit'
EOF
grads -pblc "run  plot_${VAR}_${CDATE}.gs"
fi #end plot_2dmaps

# generate time series GrADS scripts
echo $VAR ' ' plot_${VAR}_${CDATE}.ts.gs
if [ "$plot_timeseries" = "YES" ]; then
cat >plot_${VAR}_${CDATE}.ts.gs <<EOF
EXPLIST="$EXPLIST"
CDATE=$CDATE
VAR=$VAR
VARA='$VARANA'
VARA_name='$VARANA'
VARANA_TYPE='$VARANA_TYPE'
plot_monmean='$plot_monmean'
plot_diff='$plot_diff'
Nmonth=$Nmonth
PRESLEV='$PRESLEV'
LEVS=$LEVS
cmap_field="$cmap_field"
cmap_diff="$cmap_diff"
cmap_bias="$cmap_bias"
nmem=$NENS
lenexp=$lenexp

iexp=1
**get fcst monthly mean
   while (iexp<=lenexp)
      exp.iexp=subwrd(EXPLIST,iexp)
      exp=subwrd(EXPLIST,iexp)
      if (nmem>0)
         'sdfopen  $DATAOUT/'VAR'/'exp.iexp'.'CDATE'.'VAR'.mem0-'nmem'.1p0.monthly.nc'
      else
         'sdfopen  $DATAOUT/'VAR'/'exp.iexp'.'CDATE'.'VAR'.mem0.1p0.monthly.nc'
      endif
     'set t 1 'Nmonth
     'q time'
      say result
      ctime=subwrd(result,3)
      mm=substr(ctime,6,3)
      yyyy=substr(ctime,9,42)
      ctime1=subwrd(result,5)
      mm1=substr(ctime1,6,3)
      yyyy1=substr(ctime1,9,42)
      say mm
      say yyyy
      say mm1
      say yyyy1
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
      'set lon 0'
      'set lat 0'
      'define fcstGLB'iexp'=aave('varname',g)'
      'define fcstNH'iexp'=ave(ave('varname',lat=30,lat=90),lon=0,lon=360)'
      'define fcstSH'iexp'=ave(ave('varname',lat=-90,lat=-30),lon=0,lon=360)'
      'define fcstTR'iexp'=ave(ave('varname',lat=-30,lat=30),lon=0,lon=360)'
      if (VAR=SST) 
          'define fcstNINO34'iexp'=ave(ave('varname',lat=-5,lat=5),lon=190,lon=240)'
      endif
      iexp=iexp+1
      'close 1'
   endwhile

** get OBS monthly mean
   if ( VARA !='none')
      'sdfopen $anafile'
      'set time 'mm''yyyy' 'mm1''yyyy1
      if (PRESLEV='YES')
        'set lev 'LEVS
      endif
      'set lon 0'
      'set lat 0'
      'define anaGLB=aave('VARA_name',g)*fcstGLB1/fcstGLB1'
      'define anaNH=ave(ave('VARA_name',lat=30,lat=90),lon=0,lon=360)*fcstNH1/fcstNH1'
      'define anaSH=ave(ave('VARA_name',lat=-90,lat=-30),lon=0,lon=360)*fcstSH1/fcstSH1'
      'define anaTR=ave(ave('VARA_name',lat=-30,lat=30),lon=0,lon=360)'
      if (VAR=SST) 
         'define anaNINO34=ave(ave('VARA_name',lat=-5,lat=5),lon=190,lon=240)'
      endif
   else
      if (nmem>0)
         'sdfopen  $DATAOUT/'VAR'/'exp.1'.'CDATE'.'VAR'.mem0-'nmem'.1p0.monthly.nc'
      else
         'sdfopen  $DATAOUT/'VAR'/'exp.1'.'CDATE'.'VAR'.mem0.1p0.monthly.nc'
      endif
      if (PRESLEV='YES')
        'set lev 'LEVS
      endif
      'set lon 0'
      'set lat 0'
      'set t 1 'Nmonth
   endif
   say result

** plot timeseries of monthly mean
    if (VAR=SST) 
         regionlist="GLB NH SH TR NINO34"
         nreg=5
    else
         regionlist="GLB NH SH TR"
         nreg=4
    endif
  ireg=1
  while (ireg<=nreg)
     region=subwrd(regionlist,ireg)
     'set gxout shaded'
     'set grid off'
     'set grads off'
     'set xlopts 1 6 0.15'
     'set ylopts 1 6 0.15'
     'set cthick 6'
      ncolor=1

     if ( VARA !='none')
        'set ccolor '1
         'set cthick 8'
        'set xlab off'
        'set stat on'
        'd ana'region
         range=sublin(result,9)
         cmin=subwrd(range,5)
         cmax=subwrd(range,6)
         cmax=cmax+(cmax-cmin)*0.2
         cmin=cmin-(cmax-cmin)*0.2
         cint=subwrd(range,7)
         'c'
          'set vrange 'cmin' 'cmax
         'd ana'region
         expnamelist='"'VARANA_TYPE'"'
         colorlist="1"
     else
         expnamelist=""
         colorlist=""
     endif
     iexp=1
     while(iexp<=lenexp)
         iexp1=iexp+1
         'set ccolor 'iexp1
         'set cthick 6'
         colorlist=colorlist' 'iexp1
        'set xlab on'
         expnamelist=expnamelist' "'exp.iexp'"'
         if ( VARA !='none')
           'set vrange 'cmin' 'cmax
           'd fcst'region''iexp
         else
            if(iexp=1)
             'set stat on'
             'd fcst'region''iexp
              range=sublin(result,9)
              cmin=subwrd(range,5)
              cmax=subwrd(range,6)
            endif
            'set ccolor 'iexp1
            'set vrange 'cmin' 'cmax
            'd fcst'region''iexp
         endif
         iexp=iexp+1
     endwhile
     'draw title 'VAR' monthly timeseries ('region')\  ICS: 'mm' 'yyyy' NENS='nmem
      'grads-scripts/cbar_line.gs -x 2 -y 3 -c 'colorlist' -t 'expnamelist
     

'printim 'exp'.diff_'VAR'_'CDATE'_'region'.timeseries.png x1000 y1000  white'
 ireg=ireg+1
*pull dummy
'c'
 endwhile
'close 1'
reinit
'quit'
EOF
grads -pblc "run  plot_${VAR}_${CDATE}.ts.gs"
fi #end plot_timeseries

done
done


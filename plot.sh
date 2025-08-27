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
Nmonth=$Nmonth
cmap_field="$cmap_field"
cmap_diff="$cmap_diff"
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
     'sdfopen  $DATAOUT/'VAR'/'exp.iexp'.'CDATE'.'VAR'.1p0.monthly.nc'
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
       'sdfopen  $DATAOUT/'VAR'/'exp.1'.'CDATE'.'VAR'.1p0.monthly.nc'
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
            'draw title 'exp.iexp' 'VAR' \ mean='res' 'mm' 'yyyy
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
             'draw title 'exp.iexp' 'VAR' bias against 'VARANA_TYPE'\ mean='res' 'mm' 'yyyy
             iexp=iexp+1
             nplot=nplot+1
         endwhile
     endif
** plot difference between experiments
    if (lenexp>=2 & plot_diff='YES' )
       iexp=2
       while(iexp<=lenexp)
       '$GRADSDIR/subplot.gs 'nplots'  'nplot
         if(iexp=2 & VARA !='none')
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
       'draw title 'exp.iexp'-'exp.1' 'VAR' diff\ mean='res' 'mm' 'yyyy
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
grads -blc "run  plot_${VAR}_${CDATE}.gs"
done
done


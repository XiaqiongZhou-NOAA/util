EXPLIST="cfs C192mx025_sfs_reforecast_May01"
EXPNAMELIST="CFS SFSbeta1.0"
VARLIST="SST T2M"
icdate=0501
leadmonlist="1 2 3 4 5 6 7 8 9 2-4 5-7"
leadmonnamelist="0 1 2 3 4 5 6 7 8  1-3 4-6"
NENS=7
iyear=30
lats=-90
late=90
lons=0
lone=360
*box 
lon1 = 190
lon2 = 240
lat1 = -5
lat2 =5 
cmap_field="radar"
cmap_diff="blue2red"
cmap_bias="blue2red"
nmem=10

* Initialize counter
count = 1

* Loop until subwrd finds nothing
while (1)
  word = subwrd(EXPLIST, count)
  if (word = "")
    count = count - 1
    break
  endif
  count = count + 1
endwhile

say "The number of exp is: "count
lenexp=count
nplots=lenexp

ivar=1

while(1)
VAR=subwrd(VARLIST,ivar)
VARLIST="SST T2M APCP"
if (VAR = "")
    break
endif
* loop leadmonth
t=1
  while(t<12)
    leadmon=subwrd(leadmonlist,t)
    leadmonname=subwrd(leadmonnamelist,t)
    iexp=1
**get fcst monthly corr
    while (iexp<=lenexp)
      exp.iexp=subwrd(EXPLIST,iexp)
      expname.iexp=subwrd(EXPNAMELIST,iexp)
      exp=subwrd(EXPLIST,iexp)
      'sdfopen  /scratch4/NCEPDEV/ensemble/Xiaqiong.Zhou/util/sfs_diag/data/'VAR'/corr/'exp.iexp'.corr.'icdate'.'iyear'yr.nmem'NENS'.leadmon'leadmon'.nc'
      'set lat 'lats' 'late
      'set lon 'lons' 'lone
      'q file'
     'q time'
      say result
      ctime=subwrd(result,3)
      mm=substr(ctime,9,3)
      'define fcst'iexp'='VAR
         './grads-scripts/subplot.gs 'nplots'  'iexp
         './grads-scripts/color.gs -kind white->skyblue->steelblue->springgreen->yellow->orange->red->darkred->darkbrown 0.1 0.9 0.1'

         'set gxout shaded'
         'set grid off'
         'set grads off'
         'set xlopts 1 6 0.15'
         'set ylopts 1 6 0.15'
         'd fcst'iexp
         'd aave(fcst'iexp',g)'
          say result
          ress=subwrd(result,4)
          gb=substr(ress,1,5)
         'define a=aave(fcst'iexp',lon=0,lon=360,lat=-20,lat=20)'
         'd a'
          say result
          ress=subwrd(result,4)
          tr=substr(ress,1,5)
         'define a=aave(fcst'iexp',lon=190,lon=306,lat=25,lat=70)'
         'd a'
          say result
          ress=subwrd(result,4)
          na=substr(ress,1,5)
           
          'draw title 'expname.iexp' 'VAR' corr 'mm' lmon='leadmonname'\ GB='gb' TR='tr' NA='na
         './grads-scripts/cbarm.gs 1 0 1'

        'q w2xy 'lon1' 'lat1
         x1 = subwrd(result,3)
         y1 = subwrd(result,6)

       'q w2xy 'lon2' 'lat2
       x2 = subwrd(result,3)
          y2 = subwrd(result,6)

       'draw rec 'x1' 'y1' 'x2' 'y2
      iexp=iexp+1
      'close 1'
    endwhile
       'printim SFSbeta1.0.'VAR'_corr.'icdate'_leadmonth'leadmonname'.png x1000 y1000  white'
  t=t+1
  pull dummy
  'c'
  reinit
  endwhile *end of loop leadmon
ivar=ivar+1
endwhile
*'quit'

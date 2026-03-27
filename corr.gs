EXPLIST="cfs C192mx025_sfs_reforecast_March01"
EXPNAMELIST="CFS SFSbeta1.0"
VARLIST="SST T2M APCP"
icdate=0301
leadmonlist="1 2 3 4 5 6 7 8 9 2-4 5-7"
leadmonnamelist="0 1 2 3 4 5 6 7 8  1-3 4-7"
NENS=10
iyear=34
lats=-90
late=90
lons=0
lone=360
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
         './grads-scripts/color.gs -kind white->skyblue->steelblue->springgreen->yellow->orange->red->darkred 0.1 0.9 0.1'

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
           
          'draw title 'expname.iexp' 'VAR' corr 'mm' \ GB='gb' TR='tr' NA='na
         './grads-scripts/cbarm.gs 1 0 1'
      iexp=iexp+1
      'close 1'
    endwhile

  t=t+1
  pull dummy
  'c'
  reinit
  endwhile *end of loop leadmon
ivar=ivar+1
endwhile
*'quit'

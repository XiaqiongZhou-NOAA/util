EXPNAMELIST="CFS SFSbeta1.0"
VARLIST="SST T2M APCP"
VARNAMELIST="SST T2M apcp"
EXPLIST="cfs C192mx025_sfs_reforecast_Apr01"
EXPLIST="cfs C192mx025_sfs_reforecast_March01"
EXPLIST="cfs C192mx025_sfs_reforecast_May01"
EXPLIST="cfs C192mx025_sfs_reforecast_Nov01"
EXPNAMELIST="CFS SFSbeta1.0"
VAR="SST"
VARNAME="sst"
icdate=1101
leadmonlist="1 2 3 4 5 6 7 8 9 2-4 5-7"
leadmonnamelist="0 1 2 3 4 5 6 7 8  1-3 4-6"
NENS=10
iyear=34

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
  legendtxt=""
  colorlist=""
  marklist=""
* loop leadmonth
    iexp=1
    imark=2
**get fcst monthly corr
    while (iexp<=lenexp)
      exp.iexp=subwrd(EXPLIST,iexp)
      expname.iexp=subwrd(EXPNAMELIST,iexp)
      exp=subwrd(EXPLIST,iexp)
      'sdfopen  /scratch4/NCEPDEV/ensemble/Xiaqiong.Zhou/util/sfs_diag/data1/'VAR'/corr/'exp.iexp'.corr.'icdate'.'iyear'yr.'VAR'.nmem'NENS'.nino34.nc'
       'set parea 1 8 1 6'
       'set t 1 12'
       'set cthick 6'
       'set xlopts 1 6 0.15'
       'set ylopts 1 6 0.15'
       'set vrange 0.3 1'
       'set grads off'
       'set grid off'
       legendtxt=legendtxt'"'expname.iexp'" '
       colorlist=colorlist' 'iexp
       marklist=marklist' 'imark
       'set ccolor 'iexp
        'set cmark 'imark
       'd 'VAR
        iexp=iexp+1
        imark=imark+1
        'close 1'
say colorlist
say legendtxt
  pull dummy
  endwhile *end of iexp
  'grads-scripts/cbar_line.gs -x 2 -y 2 -c 'colorlist' -m 'marklist' -t 'legendtxt''
  'draw title SST Nino3.4 CORR'
 'printim SFSbeta1.0.'VAR'_corr.'icdate'_'iyear'yr.nino34.png x1000 y1000  white'
*  reinit
*'quit'

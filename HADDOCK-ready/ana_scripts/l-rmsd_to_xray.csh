set refe=$WDIR/target.pdb
set lzone=$WDIR/target.lzone
set atoms='CA,C,N,O'
#
# Define the location of profit
#
if ( `printenv |grep PROFIT | wc -l` == 0) then
  set found=`which profit |wc -l`
  if ($found == 0) then
     echo 'PROFIT environment variable not defined'
     echo '==> no rmsd calculations '
  else
     setenv PROFIT `which profit`
  endif
endif

cat /dev/null >rmsd_xray.disp

foreach i (`head -n1 file.nam`)
  if ( -e $i.gz ) then
    set CG=`gzip -dc $i.gz | grep BB | wc -l | awk '{print $1}'` 
  else
    set CG=`cat $i | grep BB | wc -l | awk '{print $1}'` 
  endif
  if ( $CG > 0 ) then
    set atoms='CA'
  endif
end

foreach i (`cat file.nam`)
  if ( -e $i.gz ) then
    gzip -dc $i.gz | sed -e 's/BB/CA/' > $i:t:r.tmp2
  else
    cat $i | sed -e 's/BB/CA/' > $i:t:r.tmp2
  endif
  $HADDOCKTOOLS/pdb_segid-to-chain $i:t:r.tmp2 |sed -e 's/BB/CA/' >$i:t:r.tmp1
  echo $i >>rmsd_xray.disp
  $PROFIT <<_Eod_ |grep RMS |tail -1 >>rmsd_xray.disp
    refe $refe
    mobi $i:r.tmp1
    ignore missing
    atom $atoms
    `cat $lzone`
    quit
_Eod_
\rm $i:r.tmp1
\rm $i:r.tmp2
end
echo "#struc l-RMSD" >l-RMSD.dat
awk '{if ($1 == "RMS:") {printf "%8.3f ",$2} else if  ($2 == "RMS:") {printf "%8.3f ",$3} else {printf "\n %s ",$1}}' rmsd_xray.disp |grep pdb |awk '{print $1,$2}' >> l-RMSD.dat
head -1 l-RMSD.dat >l-RMSD-sorted.dat
grep pdb l-RMSD.dat |sort -n -k2 >> l-RMSD-sorted.dat
\rm rmsd_xray.disp

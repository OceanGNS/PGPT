glider=echo
MISSION=$PWD/glider_data/${glider}/echo_20230113/delayed
SCRIPTS=$PWD/glider_processing_scripts

cd ${MISSION}/
mkdir txt nc 2>/dev/null

##  CONVERT BINARY TO TXT
cd ${MISSION}/raw

## NEED TO RENAME THE 0000000.*BD to glider_XXX_XXX_XX.*.bd format
${SCRIPTS}/rename_dbd_files *.*bd /

ln -s ../cache .
for f in ${glider}*bd; do
    if [[ ! -e ../txt/$f.txt ]]; then
    	echo $f
        ${SCRIPTS}/bd2ascii $f >../txt/$f.txt
    fi
done
# rm cache


###################  REALTIME  ###################
##  CONVERT TO NC
#cd ${MISSION}/txt
#for f in $(ls ${glider}*.[st]bd.txt | sed 's/\..bd\.txt//' | sort -u); do
#    if [[ ! -e ../nc/$f.nc ]]; then
#        python3 ${SCRIPTS}/realtime2nc.py $f
#    fi
#done

##  CREATE 1 NC FILE FOR THE WHOLE MISSION
#cd ${MISSION}/txt
#python3 ${SCRIPTS}/ncTimeseries.py realtime st


###################  DELAYED  ###################
##  CONVERT TO NC
cd ${MISSION}/txt
for f in $(ls ${glider}*.[de]bd.txt | sed 's/\..bd\.txt//' | sort -u); do
    if [[ ! -e ../nc/$f.nc ]]; then
        python3 ${SCRIPTS}/delayed2nc.py $f
    fi
done

##  CREATE 1 NC FILE FOR THE WHOLE MISSION
cd ${MISSION}/txt
python3 ${SCRIPTS}/ncTimeseries.py delayed de

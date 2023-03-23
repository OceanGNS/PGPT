glider=echo
MISSION=$PWD/delayed
PARENTDIR=$(builtin cd $MISSION/../../../; pwd)
SCRIPTS=$PARENTDIR/glider_processing_scripts
GLIDERS_DB=$PARENTDIR/glider_reference_information/glider_serial-numbers_and_sensor-serial-numbers.csv
# ATTR=$PWD/metadata.yml
ATTR=$PWD/master.yml


cd ${MISSION}/
mkdir txt nc 2>/dev/null

##  CONVERT BINARY TO TXT
cd ${MISSION}/raw

##  DECOMPRESS FILES IF NEEDED
for f in *.?cd; do
    ${SCRIPTS}/compexp x $f `echo $f | sed 's/cd$/bd/'`
    # rm $f  ##  Uncomment if don't want to keep compressed files
done

## NEED TO RENAME THE 0000000.*BD to glider_XXX_XXX_XX.*.bd format
${SCRIPTS}/rename_dbd_files *.*bd /

ln -s ../cache .
for f in ${glider}*bd; do
    if [[ ! -e ../txt/$f.txt ]]; then
    	echo $f
        ${SCRIPTS}/bd2ascii $f > ../txt/$f.txt
        sed -i 's/ $//' ../txt/$f.txt  ##  Remove empty space from the end of each line (pandas doesn't like them)
    fi
done
# rm cache

#################################################
##  WE NEED SOMETHING TO SWITCH IN THE SCRIPT?
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
ln -s ${SCRIPTS}/functions.py
ln -s ${SCRIPTS}/addAttrs.py
# ln -s ${GLIDERS_DB}

for f in $(ls ${glider}*.[de]bd.txt | sed 's/\..bd\.txt//' | sort -u); do
    if [[ ! -e ../nc/$f.nc ]]; then
        python3 ${SCRIPTS}/delayed2nc.py $f ${GLIDERS_DB} ${ATTR}
    fi
done

#################################################
##  No attributes in the nc timeseries file
#################################################
##  CREATE 1 NC FILE FOR THE WHOLE MISSION
cd ${MISSION}/txt
python3 ${SCRIPTS}/ncTimeseries.py delayed de

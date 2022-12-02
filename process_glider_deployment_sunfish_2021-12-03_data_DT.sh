MAIN=$PWD
glider=sunfish
MISSION=${MAIN}/glider_data/${glider}/sunfish_20211203/realtime
SCRIPTS=${MAIN}/glider_processing_scripts
metaFile=${MAIN}/metadata_glider_deployment_sunfish_2021-12-03_data_DT.txt


cd ${MISSION}/
mkdir txt nc nc_ioos 2>/dev/null

##  CONVERT BINARY TO TXT
cd ${MISSION}/raw

## NEED TO RENAME THE FILES
${SCRIPTS}/rename_dbd_files *.*bd /

ln -s ../cache .
for f in ${glider}*bd; do
    if [[ ! -e ../txt/$f.txt ]]; then
        ${SCRIPTS}/bd2ascii $f >../txt/$f.txt
    fi
done
rm cache

###################  REALTIME  ###################
##  CONVERT TO NC
cd ${MISSION}/txt
for f in $(ls ${glider}*.[st]bd.txt | sed 's/\..bd\.txt//' | sort -u); do
    if [[ ! -e ../nc/$f.nc ]]; then
        python3 ${SCRIPTS}/realtime2nc.py $f

        # ADD ATTRIBUTES
        bash ${SCRIPTS}/addAttrs.sh ${metaFile} ../nc/${f}_realtime.nc ../nc_ioos/${f}_realtime.nc
    fi
done

##  CREATE 1 NC FILE FOR THE WHOLE MISSION
cd ${MISSION}/txt
python3 ${SCRIPTS}/ncTimeseries.py realtime st

###################  DELAYED  ###################
##  CONVERT TO NC
#cd ${MISSION}/txt
#for f in $(ls ${glider}*.[de]bd.txt | sed 's/\..bd\.txt//' | sort -u); do
#    if [[ ! -e ../nc/$f.nc ]]; then
#        python3 ${SCRIPTS}/delayed2nc.py $f
#    fi
#done

##  CREATE 1 NC FILE FOR THE WHOLE MISSION
#cd ${MISSION}/txt
#python3 ${SCRIPTS}/ncTimeseries.py delayed de

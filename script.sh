MISSIONS=$PWD/sunfish/labsea_2021/realtime
SCRIPTS=$PWD

cd ${MISSIONS}/from-glider
mkdir ascii nc 2>/dev/null

##  CONVERT BINARY TO TXT
cd ${MISSIONS}/from-glider/raw
ln -s ../cache .
for f in ${glider}*bd; do
    if [[ ! -e ../ascii/$f.ascii ]]; then
        ${SCRIPTS}/bd2ascii $f >../ascii/$f.ascii
    fi
done
rm cache

##  CONVERT TO NC
cd ${MISSIONS}/from-glider/ascii
for f in $(ls | sed 's/\..bd\.ascii//' | sort -u); do
    if [[ ! -e ../nc/$f.nc ]]; then
        python3 ${SCRIPTS}/bd2nc.py $f
    fi
done

##  CREATE 1 NC FILE FOR THE WHOLE MISSION
cd ${MISSIONS}/from-glider/ascii
python3 ${SCRIPTS}/1nc.py

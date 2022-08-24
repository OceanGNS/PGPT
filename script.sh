MISSIONS=$PWD/sunfish/labsea_2021/realtime
SCRIPTS=$PWD 

cd ${MISSIONS}
mkdir ascii nc


##  CONVERT BINARY TO TXT
cd ${MISSIONS}/from-glider/raw
ln -s ../cache .
for f in ${glider}*bd; do
    # ${SCRIPTS}/bd2ascii $f > ../ascii/`echo $f | sed 's/.bd/ascii/'`
    ${SCRIPTS}/bd2ascii $f > ../ascii/$f.ascii
done
rm cache


##  CONVERT TO NC
cd ${MISSIONS}/from-glider/ascii
for f in `ls | sed 's/\..bd\.ascii//' | sort -u`; do
    python3 ${SCRIPTS}/bd2nc.py $f
done


##  CREATE 1 NC FILE FOR THE WHOLE MISSION
cd ${MISSIONS}/from-glider/ascii
python3 ${SCRIPTS}/1nc.py

MISSIONS=$PWD/sunfish/labsea_2021/realtime
SCRIPTS=$PWD 

cd ${MISSIONS}
mkdir txt cd 


##  CONVERT BINARY TO TXT
cd ${MISSIONS}/from-glider/raw
ln -s ../cache .
for f in ${glider}*bd; do
    ${SCRIPTS}/bd2txt $f > ../txt/`echo $f | sed 's/.bd/txt/'`
done
rm cache


##  CONVERT TO NC
cd ${MISSIONS}/from-glider/txt
for f in ${glider}*.txt; do
    python3 ${SCRIPTS}/bd2nc.py `basename $f .txt`
done


##  CREATE 1 NC FILE FOR THE WHOLE MISSION
cd ${MISSIONS}/from-glider/txt
python3 ${SCRIPTS}/1nc.py

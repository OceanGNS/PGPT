MISSIONS=/var/www/vhosts/mungliders.com/data.mungliders.com/missions
SCRIPTS=/var/www/vhosts/mungliders.com/scripts/bd2nc


glider='sunfish'
mission='sunfish_labrador_sea_2021'


cd ${MISSIONS}/${mission}/from-glider
mkdir txt nc


##  CONVERT BINARY TO TXT
cd ${MISSIONS}/${mission}/from-glider/raw
ln -s ../cache .
for f in ${glider}*bd; do
    ${SCRIPTS}/bd2txt $f > ../txt/`echo $f | sed 's/.bd/txt/'`
done
rm cache


##  CONVERT TO NC
cd ${MISSIONS}/${mission}/from-glider/txt
for f in ${glider}*.txt; do
    python3 ${SCRIPTS}/bd2nc.py `basename $f .txt`
done


##  CREATE 1 NC FILE FOR THE WHOLE MISSION
cd ${MISSIONS}/${mission}/from-glider/txt
python3 ${SCRIPTS}/1nc.py

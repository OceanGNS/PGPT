metaFile=$1
fIN=$2
fOUT=$3


## GLOBAL ATTRIBUTES
IFS=$'\n'
> /tmp/opts

geospatial_lat_min=`cdo infon ${fIN} | grep m_lat | awk '{print $9}'`
echo "-a geospatial_lat_min,global,o,c,'${geospatial_lat_min}'" >> /tmp/opts
geospatial_lat_max=`cdo infon ${fIN} | grep m_lat | awk '{print $11}'`
echo "-a geospatial_lat_max,global,o,c,'${geospatial_lat_max}'" >> /tmp/opts
geospatial_lon_min=`cdo infon ${fIN} | grep m_lon | awk '{print $9}'`
echo "-a geospatial_lon_min,global,o,c,'${geospatial_lon_min}'" >> /tmp/opts
geospatial_lon_max=`cdo infon ${fIN} | grep m_lon | awk '{print $11}'`
echo "-a geospatial_lon_max,global,o,c,'${geospatial_lon_max}'" >> /tmp/opts
geospatial_vertical_min=`cdo infon ${fIN} | grep m_depth | awk '{print $9}'`
echo "-a geospatial_vertical_min,global,o,c,'${geospatial_vertical_min}'" >> /tmp/opts
geospatial_vertical_max=`cdo infon ${fIN} | grep m_depth | awk '{print $11}'`
echo "-a geospatial_vertical_max,global,o,c,'${geospatial_vertical_max}'" >> /tmp/opts
time_coverage_start=`cdo infos ${fIN} | grep timestamp | awk '{print $3}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}' | xargs -I{} date -d @{} +%Y-%m-%dT%H:%M:%SZ`
echo "-a time_coverage_start,global,o,c,'${time_coverage_start}'" >> /tmp/opts
time_coverage_end=`cdo infos ${fIN} | grep timestamp | awk '{print $5}' | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}' | xargs -I{} date -d @{} +%Y-%m-%dT%H:%M:%SZ`
echo "-a time_coverage_end,global,o,c,'${time_coverage_end}'" >> /tmp/opts
time_coverage_duration=$(( (`date -d $time_coverage_end +%s` - `date -d $time_coverage_start +%s`)/60))
echo "-a time_coverage_duration,global,o,c,'M${time_coverage_duration}'" >> /tmp/opts


for line in `sed 's/#.*//; s/ *$//; /^$/d' ${metaFile}`; do
    attr=`echo ${line} | cut -d, -f1`
    value=`echo ${line} | cut -d, -f2-`
    echo "-a ${attr},global,o,c,'${value}'" >> /tmp/opts
done

opts=$(cat /tmp/opts | xargs)
cmd="ncatted -O -h ${opts} $fIN $fOUT"
eval ${cmd}
rm /tmp/opts
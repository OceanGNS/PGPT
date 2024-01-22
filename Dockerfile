FROM ubuntu:22.04
LABEL maintainer="taimaz.bahadory@mun.ca"
RUN apt -y update
RUN apt -y install python3.10 python3-pip
RUN pip3 install argparse==1.4.0 numpy==1.24.2 pandas==1.3.5 dbdreader==0.5.6 xarray==0.16.1 gsw==3.6.16 cerberus==1.3.5 pyyaml==6.0.1 netCDF4==1.6.0

COPY . /usr/src/app
WORKDIR /usr/src/app
CMD ["bash", "run.sh", "-g", "unit_334", "-d", "/usr/src/app/example", "-m", "metadata.yml", "-p", "delayed"]

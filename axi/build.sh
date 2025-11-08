#!/bin/bash
tb=$(find ./ -type f -name tb_*.v)
base=${tb%.v}
file=${base##*/}

xvlog ./*.v

if [ -z ${file} ]; then
  exit 0
fi

xelab $file -debug wave -s $file

if [ $# -le 0 ]; then
  xsim $file -gui -wdb simulate_xsim_${file}.wdb
elif [ $1 == '-c' ]; then
  xsim $file -R
else
  xsim $file -gui -wdb simulate_xsim_${file}.wdb
fi

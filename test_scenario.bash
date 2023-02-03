#!/bin/bash

## Check usage
if [ "$#" != "1" ]; then
    echo "Usage: ./test_scenario.bash <ros2 build workspace>"
    exit 1
fi

if [ ! -d "$1/install" ];
then
    echo "Path must contain prebuilt colcon work space"
    exit 1
fi

## Common environment variables
CURR_DIR=$(pwd)
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd $SCRIPT_DIR

## Build image
docker build . -t ros2_test_env

mkdir -p results

## Iterate through scenarios
for scenario1 in scenarios/*; do 
    dirname=`grep RES_DIR $scenario1`
    dirname=$(echo $dirname | sed s/RES_DIR=//g)
    mkdir -p results/$dirname
    for scenario2 in scenarios/*; do
        dirname2=`grep RES_DIR $scenario2`
        dirname2=$(echo $dirname2 | sed s/RES_DIR=//g)

        cat template/docker-compose.yml.template | sed s+ROS_BUILD_WS+$1+g > docker-compose.yml
        sed -i s+SCENARIO2_FILE+$scenario2+g docker-compose.yml
        sed -i s+SCENARIO1_FILE+$scenario1+g docker-compose.yml
        sed -i s+SCENARIO_NAME+$dirname/$dirname2+g docker-compose.yml
        
        mkdir -p results/$dirname/$dirname2/
        echo "Loading scenario $scenario1 and $scenario2"
        docker-compose up
        docker-compose down
    done
done
rm -rf docker-compose.yml
python3 report_gen.py

cd $CURR_DIR

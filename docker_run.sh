#! /bin/bash

docker run --gpus all -it --privileged --network=host -e DISPLAY --env NVIDIA_DRIVER_CAPABILITIES=compute,graphics,utility -v /home/rtaylor/MFA:/home/rtaylor/MFA px4_gazebo_darknetros:latest

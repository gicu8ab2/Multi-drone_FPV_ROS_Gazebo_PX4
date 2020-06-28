# Drone First Person View SITL with PX4+Gazebo+DarknetROS

This repo describes the setup used to "fly" multiple iris quadcopters
with virtual cameras inside a Gazebo world with mavros connections to
PX4 flight controller unit.  The docker image that contains this
multi-UAV SITL is built upon the "Multi-Vehicle Simulation with
Gazebo" section from the PX4 developer documentation given
[here](https://dev.px4.io/master/en/simulation/multi-vehicle-simulation.html).
The docker image px4_gazebo_darknetros:latest is a multistage build
that progresses as:

- nvidia/cuda:9.2-cudnn7-devel-ubuntu18.04

CUDA+CuDNN+Ubuntu18.04 base image from [here](https://gitlab.com/nvidia/container-images/cuda/blob/master/doc/supported-tags.md)

- ros_melodic_opencv:latest

Adds ROS-Melodic, OpenCV, and gstreamer from ./dockerfiles/Dockerfile_ROS_Melodic_OpenCV

- px4_gazebo_darknetros:latest

Adds PX4, Gazebo9, and DarknetROS from ./dockerfiles/Dockerfile_PX4_Gazebo_DarknetROS


## Usage

Assuming you are on a machine that already has the docker images loaded, use this command to run the
PX4+Gazebo+DarknetROS multi-drone simulation in the first console/terminal window

     docker run --gpus all -it --privileged --network=host -e DISPLAY --env NVIDIA_DRIVER_CAPABILITIES=compute,graphics,utility -v /home/rtaylor/MFA:/home/rtaylor/MFA px4_gazebo_darknetros:latest
(Note:  Swap the volume names with the correct user directory names.)

Use this command in subsequent console windows to open the same container

      docker exec -it $(docker ps | awk 'NR==2 {print $1}') bash

From inside docker container in the first terminal run

      roslaunch px4 multi_uav_mavros_sitl.launch

From inside docker container in the second terminal run

       rostopic list  # verify mavros and camera topics for each uav namespace are present
       python ./scripts/follow_people.py  # example script 1

From inside docker container in the third terminal run

       roslaunch darknet_ros yolo_v3.launch  # run Yolo_v3 object detector
       rqt &  # Plugins-->Visualization-->Image View--> <Enter camera rostopic name>


## Requirements

- Nvidia laptop with [latest Nvidia driver](https://www.nvidia.com/Download/index.aspx?lang=en-us) installed
- [Docker 19.03+](https://www.linode.com/docs/applications/containers/install-docker-ce-ubuntu-1804/)
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker)


## Moving docker images between machines
The docker images are already built and can be saved to and loaded from tar file using

    docker save -o px4_gazebo_darknetros.tar px4_gazebo_darknetros:latest
    docker load -i px4_gazebo_darknetros.tar


## Building Docker images from scratch (if needed)
If needed use this command to build the PX4+Gazebo+DarknetROS multi-drone simulation image

    cd ./dockerfiles/
    docker build -f Dockerfile_PX4_Gazebo_DarknetROS px4_gazebo_darknetros:latest .

If needed use this command to build the base ROS+OpenCV+CUDA image used to build px4_gazebo_darknetros:latest

    cd ./dockerfiles/
    docker build -f Dockerfile_ROS_Melodic_OpenCV ros_melodic_opencv:latest .


If building px4_gazebo_darknetros:latest from scratch, make the following mods:


**To add virtual camera**: add this block of code to the end of /home/PX4/Firmware/Tools/sitl_gazebo/models/rotors_description/urdf/iris_base.xacro

   \<xacro:camera_macro
  namespace="${namespace}"
  parent_link="base_link"
  camera_suffix="left"
  frame_rate="30"
  horizontal_fov="1.3962634"
  image_width="640"
  image_height="480"
  image_format="L8"
  min_distance="0.02"
  max_distance="30"
  noise_mean="0.0"
  noise_stddev="0.007"
  enable_visual="false">
  \<cylinder length="0.01" radius="0.007" />
  \<origin xyz="0.1 0 -0.1" rpy="0 1.57 0" />
  \>
\</xacro:camera_macro>


(Note: the camera model parameters can be changed here.)

**Correct port numbering error in multi_uav_mavros_sitl.launch:**
Comment out the uav0 namespace section from
/home/PX4/Firmware/launch/multi_uav_mavros_sitl.launch (increment uav
spawning from 1 and not 0 to correct mavlink_udp_port setting error)
and instead add third uav under a name space uav3 (not uav2)

**Set yaml config files with correct camera topic:**
Replace camera topic string in /home/catkin_ws/src/darknet_ros/darknet_ros/config/ros.yaml
with camera topic from

     rostopic list | grep camera | grep iris_\<ID\>

for the desired uav virtual camera FPV stream.

**Commit changes** Then (if desired) you can commit those mods to latest image using:

	 docker commit $(docker ps | awk 'NR==2 {print $1}') px4_gazebo_darknetros:latest

FROM ubuntu:16.04

ADD . /openvino/

ARG INSTALL_DIR=/opt/intel/computer_vision_sdk_2018.5.455

RUN apt-get update && apt-get -y upgrade && apt-get autoremove

#Install needed dependences
RUN  apt-get install -y --no-install-recommends \
        build-essential \
        cpio \
        curl \
	dirmngr \
	gnupg2 \
        git \
        lsb-release \
        pciutils \
        python3.5 \
        python3.5-dev \
        python3-pip \
        python3-setuptools \
        sudo \
	&& rm -rf /var/lib/apt/lists/*

# installing OpenVINO dependencies
WORKDIR /openvino/l_openvino_toolkit_p_2018.5.455
RUN  ./install_cv_sdk_dependencies.sh

RUN pip3 install numpy

# installing OpenVINO itself	
RUN sed -i 's/decline/accept/g' silent.cfg && \
    ./install.sh --silent silent.cfg

# Model Optimizer
WORKDIR $INSTALL_DIR/deployment_tools/model_optimizer/install_prerequisites 
RUN ./install_prerequisites.sh

# clean up 
RUN apt autoremove -y && \
    rm -rf /openvino/var/lib/apt/lists/*

#RUN /bin/bash -c "source $INSTALL_DIR/bin/setupvars.sh"
WORKDIR /opt/intel/computer_vision_sdk_2018.5.455/bin/ 
RUN ./setupvars.sh

RUN echo "source $INSTALL_DIR/bin/setupvars.sh" >> /root/.bashrc

WORKDIR /opt/intel/computer_vision_sdk_2018.5.455/deployment_tools/inference_engine/samples
RUN rm -rf pedestrian_tracker_demo/* \
    && git clone https://github.com/hdefazio/PedestrianTracker.git pedestrian_tracker_demo/ \
    && ./build_samples.sh

WORKDIR /root/inference_engine_samples_build/intel64/Release 
RUN git clone https://github.com/hdefazio/Sample-Data.git /root/inference_engine_samples_build/intel64/Release/sample-data


CMD ["/bin/bash"]

#setup ROS

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 421C365BD9FF1F717815A3895523BAEEB01FA116

# setup sources.list
RUN echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -sc` main" > /etc/apt/sources.list.d/ros-latest.list

# install bootstrap tools
RUN apt-get update && apt-get install --no-install-recommends -y \
    python-rosdep \
    python-rosinstall \
    python-vcstools \
    && rm -rf /var/lib/apt/lists/*

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# bootstrap rosdep
RUN rosdep init \
    && rosdep update

# install ros packages
ENV ROS_DISTRO kinetic
RUN apt-get update && apt-get install -y \
    ros-kinetic-ros-core=1.3.2-0* \
    && rm -rf /var/lib/apt/lists/*

# setup entrypoint
#COPY ./ros_entrypoint.sh /
#
#RUN "source /opt/ros/kinetic/setup.bash"
#ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]

#!/bin/bash

set -e

echo "Initial setup of SITL-vagrant instance."

BASE_PKGS="gawk make git arduino-core curl"
SITL_PKGS="g++ python-pip python-matplotlib python-serial python-wxgtk2.8 python-scipy python-opencv python-numpy python-empy python-pyparsing ccache"
PYTHON_PKGS="droneapi"
PYTHON3_PKGS="pymavlink MAVProxy"
PX4_PKGS="python-serial python-argparse openocd flex bison libncurses5-dev \
          autoconf texinfo build-essential libftdi-dev libtool zlib1g-dev \
          zip genromfs"
UBUNTU64_PKGS="libc6:i386 libgcc1:i386 gcc-4.9-base:i386 libstdc++5:i386 libstdc++6:i386"

# GNU Tools for ARM Embedded Processors
# (see https://launchpad.net/gcc-arm-embedded/)
ARM_ROOT="gcc-arm-none-eabi-4_9-2015q3"
ARM_TARBALL="$ARM_ROOT-20150921-linux.tar.bz2"
ARM_TARBALL_URL="http://firmware.ardupilot.org/Tools/PX4-tools/$ARM_TARBALL"

# Ardupilot Tools
ARDUPILOT_TOOLS="ardupilot/Tools/autotest"

sudo usermod -a -G dialout $USER

sudo apt-get -y remove modemmanager
sudo apt-get -y update
sudo apt-get -y install dos2unix g++-4.7 ccache python-lxml screen
sudo apt-get -y install $BASE_PKGS $SITL_PKGS $PX4_PKGS $UBUNTU64_PKGS
sudo pip -q install $PYTHON_PKGS
sudo pip install catkin_pkg


# ARM toolchain
if [ ! -d /opt/$ARM_ROOT ]; then
    (
        cd /opt;
        sudo wget -nv $ARM_TARBALL_URL;
        sudo tar xjf ${ARM_TARBALL};
        sudo rm ${ARM_TARBALL};
    )
fi

# Note: for Thermal Soaring also need the ~/.local/bin
exportline="export PATH=/opt/$ARM_ROOT/bin:~/.local/bin:\$PATH"
if grep -Fxq "$exportline" /home/vagrant/.profile; then echo nothing to do ; else echo $exportline >> /home/vagrant/.profile; fi

if grep -Fxq "shellinit.sh" /home/vagrant/.profile; then echo nothing to do ; else echo "source /vagrant/Tools/vagrant/shellinit.sh" >>/home/vagrant/.profile; fi

# This allows the PX4NuttX build to proceed when the underlying fs is on windows
# It is only marginally less efficient on Linux
if grep -Fxq "PX4_WINTOOL" /home/vagrant/.profile; then echo nothing to do ; else echo "export PX4_WINTOOL=y" >>/home/vagrant/.profile; fi

ln -fs /vagrant/Tools/vagrant/screenrc /home/vagrant/.screenrc

# build JSB sim
#pushd /tmp
#rm -rf jsbsim
#git clone git://github.com/tridge/jsbsim.git
#sudo apt-get install -y libtool automake autoconf libexpat1-dev
#cd jsbsim
#./autogen.sh
#make -j2
#sudo make install
#popd

#
# Setup Thermal Soaring
#
pushd /tmp

sudo apt-get -y install python3 python3-pip python3-dev libevent-dev python-wxgtk2.8 libopencv-dev
sudo pip3 -q install $PYTHON3_PKGS

# Mavlink
#git clone https://github.com/mavlink/mavlink.git mavlink
#pushd mavlink/pymavlink
#sed -i 's/select, mavexpression/select, pymavlink.mavexpression/'  mavutil.py
#python3 setup.py install --user
#popd

# Mavproxy
#git clone https://github.com/Dronecode/MAVProxy.git mavproxy
#pushd mavproxy
#python3 setup.py build install --user
#popd

# CRRCSim with APM
sudo apt-get -y install build-essential xorg-dev libudev-dev libts-dev \
    libgl1-mesa-dev libglu1-mesa-dev libasound2-dev libpulse-dev libopenal-dev \
    libogg-dev libvorbis-dev libaudiofile-dev libpng12-dev libfreetype6-dev \
    libusb-dev libdbus-1-dev zlib1g-dev libdirectfb-dev libsdl-image1.2-dev \
    libportaudio-dev libplib-dev libboost-all-dev libcgal-dev \
    python-software-properties

cores="$(grep -c ^processor /proc/cpuinfo)"

git clone https://github.com/tridge/crrcsim-ardupilot.git crrcsim-apm
pushd crrcsim-apm
./autogen.sh
./configure
make -j$cores
sudo make install
popd

# Python libraries
sudo apt-get -y install python3-matplotlib python3-scipy python3-numpy python3-pandas
sudo pip3 install -U seaborn scikit-learn
sudo pip3 install --process-dependency-links git+https://github.com/pymc-devs/pymc3

git clone git://github.com/pybrain/pybrain.git pybrain
pushd pybrain
sudo python3 setup.py install
popd

popd

# Now you can run
# vagrant ssh -c "screen -d -R"

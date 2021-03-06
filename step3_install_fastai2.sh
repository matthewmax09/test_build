#!/bin/bash
# Install Fastai2 on Nvidia Jetson Nano running Jetpack 4.4GA
# Authored by Streicher Louw, April 2020, based on previous work by
# Bharat Kunwar https://github.com/brtknr (installation of fastai) 
# and Jeffrey Antony https://github.com/jeffreyantony (use of TMUX)

# With a fast SD card, this process takes around 12-16 hours.

# As this script will take many hours to execute, the script first needs to
# cache your sudo credentials if they are not supplied on the command line

# if [ "$1" != "" ]; then
#   PW=$1
# else
#   echo "These prompts will only ask for each password once, please take care when typing"
#   echo "Please enter the sudo password"
#   read -sp 'Password: ' PW
#   echo
# fi


# now=`date`
# echo "Start Installation of fastai2 on jetson nano at: $now"

# # Update the nano's software
# echo $PW | sudo -k --stdin apt -y install apt-utils
# echo $PW | sudo -k --stdin apt -y update
# echo $PW | sudo -k --stdin apt -y upgrade
# echo $PW | sudo -k --stdin apt -y autoremove
apt-get -y update

# # sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
# # sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.5 2

# echo $PW | sudo -k --stdin apt install -y python3-pip

# # Using sudo to upgrade pip with pip a super ugly workaround, as it breaks pip in 
# # some fundemental ways see (https://github.com/pypa/pip/issues/5599), but is
# # the recommended procedure for building pytorch given by nvidia 
# # (https://forums.developer.nvidia.com/t/pytorch-for-jetson-nano-version-1-5-0-now-available/72048)
# # This is fixed again at the end of the setup stript by reinstalling the distribution pip
# echo $PW | sudo -k --stdin -H pip3 install -U setuptools 
# echo $PW | sudo -k --stdin -H pip3 install -U pip

# Install MAGMA from source
# Since fastai requires pytorch to be compiled MAGMA, MAGMA needs to be installed first
# The authors of MAGMA do not offer binary builds, so it needs to be compiled from source
now=`date`
echo "Start installation of MAGMA at: $now"
# echo $PW | sudo -k --stdin apt install -y libopenblas-dev
# echo $PW | sudo -k --stdin apt install -y libopenmpi-dev 
# echo $PW | sudo -k --stdin apt install -y gfortran
apt-get install -y libopenblas-dev
apt-get install -y libopenmpi-dev 
apt-get install -y gfortran
# echo $PW | sudo -k --stdin apt install -y cmake
wget http://icl.utk.edu/projectsfiles/magma/downloads/magma-2.5.3.tar.gz
tar -xf magma-2.5.3.tar.gz
# Magma needs a make.inc file to tell it which Nvidia architectures to compile for and where to find the blas libraries
cp make.inc.openblas magma-2.5.3/make.inc 
cd magma-2.5.3
export GPU_TARGET=Volta # Jetson Xavier Has a Volta GPU
export OPENBLASDIR=/usr/lib/aarch64-linux-gnu/openblas
export CUDADIR=/usr/local/cuda
export PATH=$PATH:/usr/local/cuda-10.2/bin
make -j6
# echo $PW | sudo -k --stdin --preserve-env make install prefix=/usr/local/magma
make install prefix=/usr/local/magma

# # For some reason, MAGMA needs a first run to configure itself or openblas correctly.
# # The first run takes a long time to get started, but after it has run through once,
# # it executes without delay on subsequent occasions.
# now=`date`
# echo "Start first run of MAGMA at: $now"
# cd testing
# python2 run_tests.py --lu --precision s --small --no-mgpu
# cd ~/

# now=`date`
# echo "Start installation of various library dependencies with apt at: $now"

# # # Install dependencies for kiwisolver
# # echo $PW | sudo -k --stdin apt install -y python3-dev

# # # Install dependencies for fastai
# # echo $PW | sudo -k --stdin apt install -y graphviz

# # # Install dependencies for pillow
# # echo $PW | sudo -k --stdin apt-get -y install libjpeg8-dev libpng-dev

# # Install dependencies for torch & torchvision
# echo $PW | sudo -k --stdin apt-get -y install openmpi-bin libjpeg-dev zlib1g-dev

# # # Install dependencies for matplotlib
# # echo $PW | sudo -k --stdin apt-get -y install libfreetype6-dev

# # # Install dependencies for Azure
# # echo $PW | sudo -k --stdin apt install -y python-cffi
# # echo $PW | sudo -k --stdin apt install -y libffi-dev
# # echo $PW | sudo -k --stdin apt install -y libssl-dev

# now=`date`
# echo "Start installation of various library dependencies with pip at: $now"

# # # Install dependencies for scipy and scikit-learn, torch, torchvision, jupyter notebook and fastai
# # pip3 install cython
# # pip3 install kiwisolver
# # pip3 install pypng
# # pip3 install dataclasses bottleneck
# # pip3 install jupyter jupyterlab
# # pip3 install pynvx
# # pip3 install pandas==1.1.1
# # pip3 install fire
# # pip3 install graphviz
# # pip3 install ipykernel
# # pip3 install azure-cognitiveservices-search-imagesearch
# # pip3 install pillow
# # pip3 install numpy
# # pip3 install scipy==1.4.1 # Must upgrade distribution scipy to match numpy
# # pip3 install scikit-learn
# # pip3 install freetype-py
# # pip3 install pyyaml
# # pip3 install future
# # BLIS_ARCH="generic" pip3 install spacy --no-binary blis
# # pip3 install matplotlib

# # Install dependencies for pytorch build
# pip3 install scikit-build --user
pip3 install ninja
pip3 install wheel

# Build torch from source
now=`date`
echo "Start installation of pytorch at: $now"
git clone --recursive --branch v1.9.0 https://github.com/pytorch/pytorch
cd pytorch/
wget https://gist.githubusercontent.com/dusty-nv/ce51796085178e1f38e3c6a1663a93a1/raw/fb2e0b6e89960fedd63ffc5a33e49e46dce5c987/pytorch-1.9-jetpack-4.5.1.patch -O pytorch-1.9-jetpack-4.5.1.patch
patch -p1 < pytorch-1.9-jetpack-4.5.1.patch
pip3 install -r requirements.txt
export USE_NCCL=0
export USE_DISTRIBUTED=0
export USE_QNNPACK=0
export USE_PYTORCH_QNNPACK=0
export TORCH_CUDA_ARCH_LIST="7.2"
export PYTORCH_BUILD_VERSION=1.9.0
export PYTORCH_BUILD_NUMBER=1
export BLAS=OpenBLAS
USE_OPENCV=1 python3 setup.py bdist_wheel # Add OpenCV support, as it is present on the nano
cd dist/
pip3 install torch-1.9.0-cp36-cp36m-linux_aarch64.whl
cd ~/

# # # Build torchvision from source
# # now=`date`
# # echo "Starting installation of torchvision at: $now"
# # git clone --branch v0.6.0 https://github.com/pytorch/vision torchvision
# # cd ~/torchvision
# # export BUILD_VERSION=0.7.0
# # python3 setup.py install --user
# # cd ~/

# # # Build sentencepiece from source
# # now=`date`
# # echo "Starting installation of sentencepiece at: $now"
# # git clone https://github.com/google/sentencepiece
# # cd ~/sentencepiece
# # mkdir build
# # cd build/
# # cmake ..
# # make -j $(nproc)
# # echo $PW | sudo -k --stdin make install
# # echo $PW | sudo -k --stdin ldconfig -v
# # cd ~/sentencepiece/python
# # python3 setup.py build
# # echo $PW | sudo -k --stdin python3 setup.py install

# # # Install fastai2 as well as fastai2 course material
# # now=`date`
# # echo "Starting installation of fastai at:" $now
# # pip3 install fastai
# # pip3 install nbdev
# # cd ~/

# # git clone https://github.com/fastai/course-v4 # clone course notebooks
# # git clone https://github.com/fastai/fastbook # clone course book

# # #Install Jypiter Notebook
# # now=`date`
# # echo "Starting installation of jupyter notebook at: $now"
# # wget https://nodejs.org/dist/v12.16.2/node-v12.16.2-linux-arm64.tar.xz
# # tar -xJf node-v12.16.2-linux-arm64.tar.xz
# # echo $PW | sudo -k --stdin cp -R node-v12.16.2-linux-arm64/* /usr/local
# # rm -rf node-v12.16.2-linux-arm64*
# # jupyter labextension install @jupyter-widgets/jupyterlab-manager
# # jupyter labextension install @jupyterlab/statusbar
# # jupyter lab --generate-config
# # jupyter nbextension enable --py widgetsnbextension

# # # Download a small script that divines the IP address, and starts jupyter notebook with the right IP
# # cp ~/fastai2_jetson_nano/start_fastai_jupyter.sh start_fastai_jupyter.sh
# # chmod a+x start_fastai_jupyter.sh

# # # Starting jpyter using the script above will mean your jupyter instance is killed when you log out or your ssh connection drops
# # # If you want jupyter to work persistently, use the tmux script below

# # # Install tmux: This section is optional, comment out if you do not want to use tmux
# # # tmux allows you to log out and leave jupyter notebook running and jetston-stas provides a very attractive way to monitor memory usage
# # # to use tmux, press command-b followed by 0,2 or 3 to switch between jtop, a terminal and jupyter's output
# # now=`date`
# # echo "Starting installation of tmux at: $now"
# # echo $PW | sudo -k --stdin apt install tmux
# # echo $PW | sudo -k --stdin -H pip3 install -U jetson-stats
# # cp ~/fastai2_jetson_nano/start_fastai_jupyter_tmux.sh start_fastai_jupyter_tmux.sh
# # chmod a+x start_fastai_jupyter_tmux.sh
# # echo $'set -g terminal-overrides \'xterm*:smcup@:rmcup@\'' >> .tmux.conf # sets up same mouse scolling in tmux
# # JPWHash=$(python3 -c "from notebook.auth import passwd; print(passwd('$JPW'))")
# # echo "{\"NotebookApp\":{\"password\":\"$JPWHash\"}}" >> ~/.jupyter/jupyter_notebook_config.json


# # # Reinstalling the distribution pip to undo sudo pip upgrade kludge (https://github.com/pypa/pip/issues/5599)
# # echo $PW | sudo -k --stdin python3 -m pip uninstall -y pip 
# # echo $PW | sudo -k --stdin apt install python3-pip --reinstall

# echo "Installation Completed"
# echo "The system will restart now. When finished, log in and run either ./start_fastai_jupyter.sh or ./start_fastai_jupyter_tmux.sh and connect with your browser to http://(your IP):8888/"
# read -t 5 a
# echo $PW | sudo -k --stdin reboot now

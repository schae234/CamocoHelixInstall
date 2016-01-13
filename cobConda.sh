#!/bin/bash
# Script to setup camoco in an anaconda environment
# Written by Joe Jeffers
# Email: jeffe174@umn.edu
# Updated October 28, 2015

# Configurable variables
export HOME=$HOME
export NAME="cobBoxTest"
export BASE="/project/csbio/jeffe174"
export GH_USER="monprin"

#===================================================
#----------Setup the build Environment--------------
#===================================================
echo "Setting up the build environment"
source $HOME/.bashrc
cd $BASE
mkdir -p $BASE/.local/lib
mkdir -p $BASE/.local/bin
mkdir -p $BASE/.conda
module load soft/python/anaconda
export LD_LIBRARY_PATH=$BASE/.local/lib:$LD_LIBRARY_PATH
export PATH=$BASE/.local/bin:$PATH

#===================================================
#----------------Install git lfs--------------------
#===================================================
if [ ! -e $BASE/.local/bin/git-lfs ]
then
    echo "Installing git-lfs for the large files in the repo"
    cd $BASE
    wget https://github.com/github/git-lfs/releases/download/v0.5.4/git-lfs-linux-amd64-0.5.4.tar.gz
    tar xzf git-lfs-linux-amd64-0.5.4.tar.gz
    rm -rf git-lfs-linux-amd64-0.5.4.tar.gz
    cd git-lfs-0.5.4/
    mv git-lfs $BASE/.local/bin/
    cd $BASE
    rm -rf git-lfs-0.5.4/
    git lfs init
fi

#===================================================
#--------------Get the Camoco Repo------------------
#===================================================
if [ ! -d $BASE/Camoco ]
then
    # git lfs init --force --skip-smudge
    git config --global credential.helper cache
    echo "Cloning the Camoco repo into $BASE"
    cd $BASE
    git clone https://github.com/$GH_USER/Camoco.git $BASE/Camoco
    # Username: schae234
    # Password: HelloGitLFS
    # git lfs uninit
    # git lfs init --force
fi
export PYTHONPATH=$PYTHONPATH:$BASE/Camoco

#===================================================
#-----Install libraries to Ensure Smoothness--------
#===================================================
if [ ! -e $BASE/.local/bin/icu-config ]
then
    echo "Installing a local version of the icu library"
    cd $BASE
    wget http://archive.ubuntu.com/ubuntu/pool/main/i/icu/icu_4.8.1.1.orig.tar.gz
    echo "Extracting the tarball"
    tar xzf icu_4.8.1.1.orig.tar.gz
    rm -rf icu_4.8.1.1.orig.tar.gz
    cd icu/source
    ./configure --prefix=$BASE/.local
    make
    make install
    cd $BASE
    rm -rf icu/
fi
if [ ! -e $BASE/.local/lib/libqhull.so ]
then
    echo "Installing a local version of the qhull library"
    cd $BASE
    wget http://www.qhull.org/download/qhull-2012.1-src.tgz
    echo "Extracting the tarball"
    tar xzf qhull-2012.1-src.tgz
    rm -rf qhull-2012.1-src.tgz
    cd qhull-2012.1
    make
    mv bin/* $BASE/.local/bin/
    mv lib/* $BASE/.local/lib
    ln -s $BASE/.local/lib/libqhull.so $BASE/.local/lib/libqhull.so.5
    cd $BASE
    rm -rf qhull-2012.1/
fi

#===================================================
#------------------Install mcl----------------------
#===================================================
if [ ! -e $BASE/.local/bin/mcl ]
then
    echo "Installing mcl locally"
    cd $BASE
    wget http://micans.org/mcl/src/mcl-latest.tar.gz
    echo "Extracting the taball"
    tar xzvf mcl-latest.tar.gz
    rm -rf mcl-latest.tar.gz
    cd $(find . -name 'mcl-*' -type d | head -n 1)
    ./configure --prefix=$BASE/.local
    make
    make install
    cd $BASE
    rm -rf $(find . -name 'mcl-*' -type d | head -n 1)
fi

#===================================================
#----------Build the Conda Environment--------------
#===================================================
echo "Making the conda virtual environment named $NAME in $BASE/.conda"
cd $BASE
conda config --add envs_dirs $BASE/.conda
conda create -y -n $NAME --no-update-deps python=3 anaconda setuptools pip distribute cython nose six pyyaml yaml pyparsing python-dateutil pytz numpy scipy pandas matplotlib numexpr patsy statsmodels pytables flask networkx ipython
conda install --no-update-deps -y -n $NAME -c http://conda.anaconda.org/omnia termcolor
conda install --no-update-deps -y -n $NAME -c http://conda.anaconda.org/cpcloud ipdb
source activate $NAME

#===================================================
#-----------------Install apsw----------------------
#===================================================
echo "Installing apsw into the conda environment"
cd $BASE
git clone https://github.com/rogerbinns/apsw.git
cd apsw
python setup.py fetch --missing-checksum-ok --all build --enable-all-extensions install
cd $BASE
rm -rf apsw

#===================================================
#------------Update the bashrc----------------------
#===================================================
echo "Updating your $HOME/.bashrc as needed"
if ! grep -q "soft/python/anaconda" $HOME/.bashrc
then
    echo "module load soft/python/anaconda" >> $HOME/.bashrc
fi
if ! grep -q "$BASE/Camoco" $HOME/.bashrc
then
    echo "export PYTHONPATH=\$PYTHONPATH:$BASE/Camoco" >> $HOME/.bashrc
fi
if ! grep -q "LD_LIBRARY_PATH=$BASE/.local/lib" $HOME/.bashrc
then
    echo "export LD_LIBRARY_PATH=$BASE/.local/lib:\$LD_LIBRARY_PATH" >> $HOME/.bashrc
fi
if ! grep -q "PATH=$BASE/.local/bin" $HOME/.bashrc
then
    echo "export PATH=$BASE/.local/bin:\$PATH" >> $HOME/.bashrc
fi

#===================================================
#-------------Use Instructions----------------------
#===================================================
echo " "
echo "All done, to use your new environment, first restart the shell."
echo "Then type: source activate $NAME"
echo "To leave it, type: source deactivate"
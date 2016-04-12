#!/bin/bash
# Script to setup camoco in an anaconda environment
# Written by Joe Jeffers
# Email: jeffe174@umn.edu
# Updated January 20, 2015


function usage(){
cat <<EOF
    Usage: $0 [flags]

    Flags
    -----
    -h | --help
        print help message
    -b | --base
        Base installation directory for camoco (default: ~/.camoco).
    -g | --github-user
        Optional github user to clone Camoco repo from (default: schae234)
EOF
exit 0
}

# Configurable variables
GH_USER='schae234'
BASE=~/.camoco/

while [[ $# > 0 ]]
do
key="$1"
case $key in 
    -h|--help)
    usage
    shift
    ;;
    -b|--base)
    BASE=$2
    shift
    ;;
    -g|--github-user)
    GH_USER=$2
    shift
    ;;
    *)  
        #unknown options
    ;;
esac
shift
done

echo $BASE $GH_USER

export NAME="camoco"
[ -z "$BASE" ] && { usage; echo "Error: Set the --base option."; exit 1; }
[ -z "$GH_USER" ] && { usage; echo "Error: Set the --github-user option"; exit 1; }

exit 0;

#===================================================
#----------Setup the build Environment--------------
#===================================================
echo "Setting up the build environment"
source $HOME/.bashrc
cd $BASE
mkdir -p $BASE/.local/lib
mkdir -p $BASE/.local/bin
mkdir -p $BASE/.conda
export LD_LIBRARY_PATH=$BASE/.local/lib:$LD_LIBRARY_PATH
export PATH=$BASE/.local/bin:$PATH

#===================================================
#----------------Install conda ---------------------
#===================================================
if ! hash conda 2>/dev/null ; then
	wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh;
	bash miniconda.sh -b -f -p $BASE/.local
	rm -rf miniconda.sh
fi

#===================================================
#----------------Install git lfs--------------------
#===================================================
if ! hash git-lfs 2>/dev/null ; then
    echo "Installing git-lfs for the large files in the repo"
    cd $BASE
    wget https://github.com/github/git-lfs/releases/download/v1.1.0/git-lfs-linux-amd64-1.1.0.tar.gz
    tar xzf git-lfs-linux-amd64-1.1.0.tar.gz
    rm -rf git-lfs-linux-amd64-1.1.0.tar.gz
    cd git-lfs-1.1.0/
    rm -rf $BASE/.local/bin/git-lfs*
    mv git-lfs $BASE/.local/bin/
    cd $BASE
    rm -rf git-lfs*
    git lfs install
    git lfs uninstall
fi

#===================================================
#--------------Get the Camoco Repo------------------
#===================================================
if [ ! -d $BASE/Camoco ]
then
    git config --global credential.helper cache
    echo "Cloning the Camoco repo into $BASE"
    cd $BASE
    git clone https://github.com/$GH_USER/Camoco.git $BASE/Camoco
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
conda remove -y --name $NAME --all
conda create -y -n $NAME --no-update-deps python=3.4 anaconda setuptools pip distribute \
    cython==0.22.1 nose six pyyaml yaml pyparsing python-dateutil pytz numpy \
    scipy pandas matplotlib==1.4.3 numexpr patsy statsmodels pytables flask \
    networkx ipython mpmath
conda install --no-update-deps -y -n $NAME -c http://conda.anaconda.org/omnia termcolor
conda install --no-update-deps -y -n $NAME -c http://conda.anaconda.org/cpcloud ipdb
export LD_LIBRARY_PATH=$BASE/.local/lib:\$LD_LIBRARY_PATH
export PATH=$BASE/.local/bin:\$PATH


#===================================================
#----------Activate the Conda Environment-----------
#===================================================
source activate $NAME

#==================================================
#----------Take care of some pip packages ---------
#==================================================
pip install powerlaw
pip install sklearn

#===================================================
#-----------------Install apsw----------------------
#===================================================
echo "Installing apsw into the conda environment"
cd $BASE
rm -rf apsw
git clone https://github.com/rogerbinns/apsw.git
cd apsw
python setup.py fetch --missing-checksum-ok --all build --enable-all-extensions install
cd $BASE
rm -rf apsw

#==================================================
#-----------------Install Camoco-------------------
#=================================================
echo "Installing Camoco"
cd $BASE
python setup.py install


#===================================================
#------------Update the bashrc----------------------
#===================================================
echo "Update your $HOME/.bashrc:"
echo "export LD_LIBRARY_PATH=$BASE/.local/lib:\$LD_LIBRARY_PATH" >> $HOME/.bashrc
echo "export PATH=$BASE/.local/bin:\$PATH" >> $HOME/.bashrc

#===================================================
#-------------Use Instructions----------------------
#===================================================
echo " "
echo "All done, to use your new environment, first restart the shell."
echo "Then type: source activate $NAME"
echo "To leave it, type: source deactivate"

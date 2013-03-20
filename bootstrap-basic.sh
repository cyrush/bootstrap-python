#!/bin/bash
#
# bootstrap-python.sh
#
# ``Minimal'' zero to Python bash script.
#
#  Builds Python in place with a few common modules.
# 
#

export PY_VERSION="2.7.3"

function info
{
    echo "$@"
}

function warn
{
    info "WARNING: $@"
}

function error
{
    info "ERROR: $@"
    exit 1
}

function check
{
    if [[ $1 != 0 ]] ; then
        error " !Last step failed!"
    fi
}

function download
{
    if [[ -e $2 ]] ; then
        info "Found: $2 <Skipping download>" 
        return 0
    fi
    info "NOT Found: $2 <Downloading from $1>"
    WGET_TEST=$(which wget)
    if [[ $WGET_TEST == "" ]] ; then
        curl -ksfLO $1/$2
    else
        wget $1/$2
    fi
}

function check_python_install
{
    if [[ -e $1/python/$PY_VERSION/bin/python ]] ; then
        return 0
    else
        return 1
    fi
}

function set_install_path
{
    export START_DIR=`pwd`
    export BUILD_DIR=$1/_build
    export LOGS_DIR=$BUILD_DIR/logs
    export PY_ROOT=$1/python
    export PY_PREFIX=$PY_ROOT/$PY_VERSION
    export PY_EXE=$PY_PREFIX/bin/python
    export PIP_EXE=$PY_PREFIX/bin/pip
}

function bootstrap_python
{
    mkdir $BUILD_DIR
    mkdir $PY_ROOT
    mkdir $PY_PREFIX
    mkdir $LOGS_DIR

    info "================================="
    info "Bootstraping Python $PY_VERSION"
    info "================================="
    info "[Target Prefix: $PY_PREFIX]"
    cd $BUILD_DIR
    download http://www.python.org/ftp/python/$PY_VERSION Python-$PY_VERSION.tgz
    rm -rf Python-$PY_VERSION
    tar -xzf Python-$PY_VERSION.tgz
    cd Python-$PY_VERSION
    info "[Configuring Python]"
    ./configure --prefix=$PY_PREFIX &> ../logs/python_configure.txt
    check $?
    info "[Building Python]"
    make -j 4 &> ../logs/python_build.txt
    check $?
    info "[Installing Python]"
    make install &> ../logs/python_install.txt
    check $?

    cd $START_DIR   
}

function bootstrap_modules
{
    # bootstrap pip
    info "================================="
    info "Bootstraping base modules"
    info "================================="
    cd $BUILD_DIR
    download http://pypi.python.org/packages/source/d/distribute distribute-0.6.30.tar.gz
    rm -rf distribute-0.6.30
    tar -xzf distribute-0.6.30.tar.gz
    cd distribute-0.6.30
    info "[Building distribute]"
    $PY_EXE setup.py build  &> ../logs/distribute_build.txt
    check $?
    info "[Installing distribute]"
    $PY_EXE setup.py install &> ../logs/distribute_install.txt
    check $?
    
    cd $BUILD_DIR
    download http://pypi.python.org/packages/source/p/pip pip-1.2.1.tar.gz
    rm -rf pip-1.2.1
    tar -xzf pip-1.2.1.tar.gz
    cd pip-1.2.1
    info "[Building pip]"
    $PY_EXE setup.py build &> ../logs/pip_build.txt
    check $?
    info "[Installing pip]"
    $PY_EXE setup.py install &> ../logs/pip_install.txt
    check $?

    cd $START_DIR
}


function main
{
    # Possible Feature: Check for DEST passed as $1, use `pwd` as fallback
    DEST=`pwd`
    set_install_path $DEST
    check_python_install $DEST
    if [[ $? == 0 ]] ; then
        info "[Found: Python $PY_VERSION @ $DEST/$PY_VERSION/bin/python <Skipping build>]"
    else
        bootstrap_python 
        bootstrap_modules     
    fi
    # Only add to PATH if `which python` isn't our Python
    PY_CURRENT=`which python`
    if [[ "$PY_CURRENT" != "$PY_PREFIX/bin/python" ]] ; then
        export PATH=$PY_PREFIX/bin:$PATH
    fi

    info "[Active Python:" `which python` "]"
}

main 

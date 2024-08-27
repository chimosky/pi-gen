#!/bin/bash
set -e

# install git if not present
[ ! -e /usr/bin/git ] && apt install -y git

# make place to put sources
#C=cache.sugar/usr/src
#mkdir -p $C

cd /usr/src/
# clone the sugar modules
for x in sugar{-datastore,-artwork,-toolkit-gtk3,} gwebsockets; do
    git clone --depth 2 https://github.com/sugarlabs/$x $P
done

# prepare for activities
mkdir -p $C/sugar-activities

function clone {
    #P=$C/sugar-activities/$2
    P=/usr/src/sugar-activities/$2
    if [ ! -e $P ]; then
	git clone --depth 2 $1 $P
    fi
}

# clone demonstration activities, the fructose set
clone https://github.com/sugarlabs/browse-activity      Browse.activity
clone https://github.com/sugarlabs/sugarlabs-calculate  Calculate.activity
clone https://github.com/sugarlabs/chat                 Chat.activity
clone https://github.com/sugarlabs/imageviewer-activity ImageViewer.activity
clone https://github.com/sugarlabs/jukebox-activity     Jukebox.activity
clone https://github.com/sugarlabs/log-activity         Log.activity
clone https://github.com/sugarlabs/Pippy                Pippy.activity
clone https://github.com/sugarlabs/read-activity        Read.activity
clone https://github.com/sugarlabs/terminal-activity    Terminal.activity
clone https://github.com/sugarlabs/turtleart-activity   TurtleBlocks.activity
clone https://github.com/sugarlabs/write-activity       Write.activity

# clone assorted other activities, the honey set
clone https://github.com/sugarlabs/memorize-activity Memorize.activity

# build - sugar-datastore

# build - sugar-artwork
cd /usr/src/sugar-artwork && (
    echo "Building sugar-artwork"
    ./autogen.sh --prefix=/usr
    make
    make install
    echo ok
) > /usr/src/install-sugar-artwork.log 2>&1

# build - sugar-toolkit-gtk3
cd /usr/src/sugar-toolkit-gtk3 && (
    echo "Building sugar-toolkit-gtk3"
    ./autogen.sh --prefix /usr --with-python3
    make
    make install
    rsync -r /usr/lib/python3.11/site-packages/sugar3 /usr/lib/python3/dist-packages/
    git clean -dfx
    ./autogen.sh --prefix /usr --with-python2
    make
    make install
    echo ok
) > /usr/src/install-sugar-toolkit-gtk3.log 2>&1

cd /usr/src/sugar-datastore && (
    echo "Building sugar-datastore"
    ./autogen.sh --prefix /usr
    make
    make install
    rsync -r /usr/lib/python3.11/site-packages/carquinyol /usr/lib/python3/dist-packages/
    echo ok
) > /usr/src/install-sugar-datastore.log 2>&1

# build - sugar
cd /usr/src/sugar && (
    echo "Building sugar"
    ./autogen.sh --prefix /usr
    make
    make install
    mv /usr/lib/python3.11/site-packages/jarabe /usr/lib/python3/dist-packages/
    echo ok
) > /usr/src/install-sugar.log 2>&1

# build - gwebsockets
cd /usr/src/gwebsockets && (
    echo "Building gwebsockets"
    git clean -dfx
    python3 setup.py build
    python3 setup.py install --prefix /usr
    cp -pr gwebsockets /usr/lib/python3/dist-packages/
    echo ok
) > /usr/src/install-gwebsockets.log 2>&1

# replace all installed activities with sugar activities from source
# side effect: debian package version mismatch
(
    mkdir /usr/share/sugar/activities
    cd /usr/src/sugar-activities
    for ACTIVITY in *.activity; do
        echo $ACTIVITY
        rm -rf /usr/share/sugar/activities/$ACTIVITY
        (cd /usr/share/sugar/activities &&
                ln -s /usr/src/sugar-activities/$ACTIVITY) && echo ok
    done
) > /usr/src/install-sugar-activities.log 2>&1


echo "
#!/bin/bash
sugar
exit
" > $HOME/.xsession

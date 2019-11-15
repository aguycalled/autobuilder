set -e 

REPO=$1
BRANCH=$2
PR=$3
URL=https://github.com/$REPO/navcoin-core.git
ACCESS_TOKEN=g17h084cc351704e1
JOBS=7
MEMORY=24000

rm -rf ~/navcoin-core ; cd ~ && git clone ${URL} --branch ${BRANCH}
cd ~/navcoin-core && git pull ; git checkout ${BRANCH} ; git pull
mkdir -p ~/public_html/binaries/$BRANCH/log/win
mkdir -p ~/public_html/binaries/$BRANCH/log/osx
mkdir -p ~/public_html/binaries/$BRANCH/log/linux

touch ~/public_html/binaries/$BRANCH/.lastbuild

LASTCOMMIT=$(git log -n 1 --pretty=format:"%H")
LASTBUILD=$(cat ~/public_html/binaries/$BRANCH/.lastbuild)

if [ "$LASTCOMMIT" == "$LASTBUILD" ]
then
   exit 0
fi

make -C ~/navcoin-core/depends download SOURCES_PATH=`pwd`/cache/common
cd ~/gitian-builder &&\
USE_DOCKER=1 ./bin/gbuild --memory ${MEMORY} -j${JOBS} --commit navcoin-core=${BRANCH} --url navcoin-core=${URL} ../navcoin-core/contrib/gitian-descriptors/gitian-win.yml &&\
mv build/out/navcoin-*.tar.gz build/out/src/navcoin-*.tar.gz ~/public_html/binaries/$BRANCH/ &&\
cp var/install.log ~/public_html/binaries/$BRANCH/log/win/ &&\
cp var/build.log ~/public_html/binaries/$BRANCH/log/win/ &&\
cd ~/public_html/binaries/$BRANCH && rm *SHA256SUM* ; sha256sum n* > $BRANCH.SHA256SUM.asc &&\

cd ~/gitian-builder &&\
USE_DOCKER=1 ./bin/gbuild --memory ${MEMORY}  -j${JOBS} --commit navcoin-core=${BRANCH} --url navcoin-core=${URL} ../navcoin-core/contrib/gitian-descriptors/gitian-osx.yml &&\
mv build/out/navcoin-*.tar.gz build/out/src/navcoin-*.tar.gz ~/public_html/binaries/$BRANCH/ &&\
cp var/install.log ~/public_html/binaries/$BRANCH/log/osx/ &&\
cp var/build.log ~/public_html/binaries/$BRANCH/log/osx/ &&\
cd ~/public_html/binaries/$BRANCH && rm *SHA256SUM* ; sha256sum n* > $BRANCH.SHA256SUM.asc &&\

cd ~/gitian-builder &&\
USE_DOCKER=1 ./bin/gbuild --memory ${MEMORY}  -j${JOBS} --commit navcoin-core=${BRANCH} --url navcoin-core=${URL} ../navcoin-core/contrib/gitian-descriptors/gitian-linux.yml &&\
mv build/out/navcoin-*.tar.gz build/out/src/navcoin-*.tar.gz ~/public_html/binaries/$BRANCH/ &&\
cp var/install.log ~/public_html/binaries/$BRANCH/log/linux/ &&\
cp var/build.log ~/public_html/binaries/$BRANCH/log/linux/ &&\
cd ~/public_html/binaries/$BRANCH && rm *SHA256SUM* ; sha256sum n* > $BRANCH.SHA256SUM.asc &&\

rm ~/public_html/binaries/$BRANCH/*debug* &&\
cd ~/public_html/binaries/$BRANCH && rm *SHA256SUM* ; sha256sum n* > $BRANCH.SHA256SUM.asc &&\

if (( $PR > 0 ));
then
   curl -s -H "Authorization: token ${ACCESS_TOKEN}" \
    -X POST -d '{"body": "A new build of ${LASTCOMMIT} has completed succesfully!\nBinaries available at https://build.nav.community/binaries/${BRANCH}"}' \
    "https://api.github.com/repos/${REPO}/navcoin-core/issues/${PR}/comments"
fi

echo $LASTCOMMIT >  ~/public_html/binaries/$BRANCH/.lastbuild

sleep 30
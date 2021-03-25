#!/bin/bash
cd /src/
# run codeql 
if [ -s cpp-db ];then
	rm -r cpp-db
fi
echo "Install the dependencies for compiling the repository"
sed -i~orig -e 's/# deb-src/deb-src/' /etc/apt/sources.list
apt-get update -yqq
dpkg --configure -a
DEBIAN_FRONTEND="noninteractive" apt-get install -yqq tzdata
apt-get -yqq build-dep bluez
./bootstrap
./configure --prefix=/usr --mandir=/usr/share/man --sysconfdir=/etc --localstatedir=/var
echo "Create the codeql database" 
codeql database create cpp-db --language=cpp --command="make -j16"
echo "Run the queries to find results"
codeql database analyze -j0 cpp-db /root/codeql-repo/cpp/ql/src/Likely\ Bugs/ \
	/root/codeql-repo/cpp/ql/src/Best\ Practices/ \
	/root/codeql-repo/cpp/ql/src/Critical/ \
	/root/codeql-repo/cpp/ql/src/experimental/ \
	--format=csv --output cpp-results.csv

CWE=$(ls -d /root/codeql-repo/cpp/ql/src/Security/CWE/* | grep -v CWE-020)
codeql database analyze -j0 cpp-db $CWE --format=csv --output cpp-security-results.csv


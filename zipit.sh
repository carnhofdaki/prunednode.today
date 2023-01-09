#!/bin/sh
#
# Usage: ./zipit.sh [<bitdir> [<bitout> [<wwwdir>]]]
# Example: ./zipit.sh $HOME/.bitcoin /root/snapshots/core_snapshot /var/www/html

bitdir=${1:-"$HOME/.bitcoin"}
bitout=${2:-"/root/snapshots/core_snapshot"}
wwwdir=${3:-"/var/www/html"}
bitpid=$(cat $bitdir/bitcoind.pid)

# Bitcoin Daemon Here - starts a bitcoind in current directory
bdh() {
  test -d "$1" && { MYDIR="$1"; shift; }
  OPTS="$@"
  sh -se <<-EOF
	test "$MYDIR" = "" || cd "$MYDIR"

	test "\${PWD##*/}" = "signet" && chain=signet
	test "\${PWD##*/}" = "testnet3" && chain=test
	test "\${PWD##*/}" = "regtest" && chain=regtest
	test "\$chain" = "" || bd=\${PWD%/*}

	exec bitcoind "-datadir=\${bd:-\$PWD}" -chain=\${chain:-main} $OPTS
	EOF
}

# Bitcoin Client Here - starts a bitcoin-cli in current directory
bch() {
  test -d "$1" && { MYDIR="$1"; shift; }
  OPTS="$@"
  sh -se <<-EOF
	test "$MYDIR" = "" || cd "$MYDIR"

	test "\${PWD##*/}" = "signet" && chain=signet
	test "\${PWD##*/}" = "testnet3" && chain=test
	test "\${PWD##*/}" = "regtest" && chain=regtest
	test "\$chain" = "" || bd=\${PWD%/*}

	exec bitcoin-cli "-datadir=\${bd:-\$PWD}" -chain=\${chain:-main} $OPTS
	EOF
}

bch $bitdir stop
while kill -0 $bitpid; do printf .; sleep 1; done; echo

now=$(date +"%y%m%d")
mkdir -p $bitout

cp -r $bitdir/chainstate $bitout/
cp -r $bitdir/blocks $bitout/
cp $bitdir/bitcoin.conf $bitout/

bdh $bitdir -disablewallet -daemon

cd $bitout
zip -r ../snapshot${now}.zip ./*
cd ..
rm -rf $bitout
sha256sum snapshot${now}.zip > snapshot${now}.txt
mv snapshot* $wwwdir

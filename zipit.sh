#!/bin/sh
#
# Usage: ./zipit.sh [<bitdir>]
# Example: ./zipit.sh $HOME/.bitcoin

bitdir=${1:-"$HOME/.bitcoin"}
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
mkdir /root/snapshots/core_snapshot
cp -r /root/.bitcoin/chainstate /root/snapshots/core_snapshot/chainstate
cp /root/.bitcoin/fee_estimates.dat /root/snapshots/core_snapshot/
cp /root/.bitcoin/bitcoin.conf /root/snapshots/core_snapshot/
cp -r /root/.bitcoin/blocks /root/snapshots/core_snapshot/blocks
cp /root/.bitcoin/mempool.dat /root/snapshots/core_snapshot/

bdh $bitdir -disablewallet -daemon

cd /root/snapshots/core_snapshot/
zip -r ../snapshot${now}.zip ./*
cd ..
rm -rf core_snapshot
sha256sum snapshot${now}.zip > snapshot${now}.txt
mv snapshot* /var/www/html/


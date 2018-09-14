#!/bin/bash

set -e
set -x

. "${0%/*}/bcm2835-branches.sh.dot"
. "${0%/*}/lib.sh"

prefix=

usage()
{
	echo "usage: $1 [options]"
	echo ""
	echo "options:"
	echo "  -v, --reroll-count <n>    mark set of pull requests as the <n>-th iteration"
}

while test $# -gt 0; do
	case $1 in
		--reroll-count | -v)
			if test -n "$2"; then
				prefix=v${2}-
				shift 2
			else
				usage $0
				exit 1
			fi
			;;

		*)
			usage $0
			exit 1
			;;
	esac
done

git_tag_get_subject()
{
	local blank=no

	git checkout $1
	git describe --abbrev=0 --tags
}

repository=git://github.com/anholt/linux
remote=$(get_remote)

to="Florian Fainelli <f.fainelli@gmail.com>"
cc="Eric Anholt <eric@anholt.net>"
cc="$cc, Stefan Wahren <stefan.wahren@i2se.com>"
cc="$cc, linux-kernel@vger.kernel.org"
cc="$cc, bcm-kernel-feedback-list@broadcom.com"
cc="$cc, linux-rpi-kernel@lists.infradead.org"
cc="$cc, linux-arm-kernel@lists.infradead.org"

index=1
count=0

for branch in ${arm_soc}; do
	count=$[count + 1]
done

for branch in ${arm_soc}; do
	tag=$(git_tag_get_subject bcm2835-${branch//\//-}) 
	release=${branch%%/*}

	if ! test -d "pull-request"; then
		mkdir -p "pull-request"
	fi

	message=$(printf "pull-request/$prefix%04u-$tag" $index)
	name=$(git config --get user.name)
	email=$(git config --get user.email)
	date=$(date -R)
	subject=$tag

	if ! git config --get sendemail.from > /dev/null 2>&1; then
		identity=$(git config --get sendemail.identity)
		from=$(git config --get sendemail.$identity.from)
	else
		from=$(git config --get sendemail.from)
	fi

	if test -f "$message"; then
		echo "ERROR: file $message already exists"
		exit 1
	fi

	exec 3> "$message"

	echo "From $email $date" >&3
	echo "From: $from" >&3
	echo "To: $to" >&3
	echo "Cc: $cc" >&3
	printf "Subject: [GIT PULL %01u/%01u] $subject\n" $index $count >&3
	echo "" >&3
	echo "Hi Florian," >&3
	echo "" >&3
	git request-pull $merge_base $repository $tag >&3; rc=$?

	exec 3>&-

	if test "x$rc" != "x0"; then
		rm "$message"
	fi

	index=$[index + 1]
done

#!/bin/bash

get_remote()
{
	path=pub/scm/linux/kernel/git/tegra/linux.git
	var=$1

	git remote -v | while read name url spec; do
		case "$url" in
			*.kernel.org:/$path | *.kernel.org:$path)
				echo "$name"
				break
				;;

			*)
				;;
		esac
	done
}

function cross_compile_prepare()
{
	local arch key value path

	case $1 in
		aarch64)
			arch=arm64
			;;

		*)
			arch=$1
			;;
	esac

	if test -f "$HOME/.cross-compile"; then
		while read key value; do
			key="${key%:}"

			if test "$key" = "path"; then
				eval "value=$value"

				if test -n "$path"; then
					path="$path:$value"
				else
					path="$value"
				fi
			elif test "$key" = "$arch"; then
				if test -n "$CROSS_COMPILE"; then
					saved_CROSS_COMPILE="$CROSS_COMPILE"
				fi

				ARCH=$arch; CROSS_COMPILE="$value"
				export ARCH CROSS_COMPILE
			fi
		done < "$HOME/.cross-compile"
	fi

	if test -n "$path"; then
		saved_PATH="$PATH"
		PATH="$path:$PATH"
	fi
}

function cross_compile_cleanup()
{
	if test -n "$saved_CROSS_COMPILE"; then
		CROSS_COMPILE="$saved_CROSS_COMPILE"
	else
		unset CROSS_COMPILE
	fi

	if test -n "$saved_PATH"; then
		PATH="$saved_PATH"
	fi
}

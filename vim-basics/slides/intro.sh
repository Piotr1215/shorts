#!/usr/bin/env bash

title="Neo(vim): Introduciton"

if command -v figlet &>/dev/null && command -v boxes &>/dev/null; then
	echo "$title" | figlet -f big | lolcat | boxes -d peek
else
	echo "$title"
fi

#!/bin/sh
# SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: GPL-2.0-only

url="https://blocklistproject.github.io/Lists/alt-version"
dir="blocklist"
lists="abuse ads crypto drugs facebook fraud gambling malware phishing\
	piracy porn ransomware redirect scam tiktok torrent tracking"

mkdir -p ${dir}
for name in ${lists}; do
	file="${name}-nl.txt"
	list="${dir}/${file}"
	printf "downloading ${file}\n"
	curl -# "${url}/${file}" -o ${list}
	script="${dir}/${name}.lua"
	echo "return {" > ${script}
	grep -Ev '^.{64}|[^a-zA-Z0-9.-]' ${list} |\
		sed "s/\([a-zA-Z0-9.-]*\)/\[\"\1\"\]=true,/g" >> ${script}
	echo "}" >> ${script}
	rm ${list}
done

# create example blocklist for dev purposes
echo "return {
[\"ebpf.io\"]=true,
}" > ${dir}/example.lua

#!/bin/sh
# SPDX-FileCopyrightText: (c) 2024 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: GPL-2.0-only

url="https://blocklistproject.github.io/Lists/alt-version"
dir="blocklist"
lists="abuse ads basic crypto drugs facebook fortnite fraud\
	gambling malware phishing piracy porn ransomware redirect scam\
	scam-tv tiktok torrent tracking twitter vaping whatsapp youtube"

mkdir -p ${dir}
for name in ${lists}; do
	file="${name}-nl.txt"
	list="${dir}/${file}"
	printf "downloading ${file}\n"
	curl -# "${url}/${file}" -o ${list}
	lua blocklist.lua ${name}
done


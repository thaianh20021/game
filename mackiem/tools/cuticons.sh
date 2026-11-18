#!/usr/bin/env bash
# Cuts the icon sheets from tools/icons.sh into Assets/Resources/Art/icon_<id>.png (relics, manuals, rewards).
c() { python tools/cut.py gen/raw_$1.png "$2" 128 each > /dev/null && echo "$1 cut" || echo "$1 FAILED"; }
P() { local o=""; for n in "$@"; do o="$o,icon_$n"; done; echo "${o:1}"; }
c icons_r1 "$(P huyetngoc phonghai kimcang phongan thattinh dandien toaithach hoalinh bangtam ngoctuy satky phuongvu)"
c icons_r2 "$(P thamlang lieudiep amduong cuongbao nghichhanh tumau thienquan thaicuc thoathe bikip tra ngan)"
c icons_b1 "$(P a0 a1 a2 a3 a4 d0 d1 d2 d3 d4 p0 p1)"
c icons_b2 "$(P p2 p3 p4 s0 s1 s2 s3 s4 hp qi dash sinh)"
c icons_b3 "$(P khac break leech coin crit calm ripo fin kiem hoi sect lantern)"

extends RefCounted
# Hand-drawn pose frames. For each sprite: the rows that change, by row number, drawn in the
# same palette letters as the base map in art.gd (rows must keep their length).
#   "b" = wind-up / blink (eyes shut, glow dimmed, wings folded)
#   "l" = attack (eyes flare, mouth opens, arms or horns spread, core blazes)
# Keys are map names, so foes that share a map with a colour swap share these frames.
# The generated motion (sink for b, forward lean for l) is applied on top.

const HAND = {
	# ---- heroes ----
	"h_warden": {
		"b": {3: "..yekkkkey..", 8: ".gyeoyyoeyg."},
		"l": {3: "..yekwwkey..", 6: "gyyeeeeeeyyg", 7: ".gyeoYYoeyg.", 8: ".gyeYwwYeyg."},
	},
	"h_arcanist": {
		"b": {2: "...KyyyyK...", 3: "...KyYYyK...", 4: "...KyyyyK..."},
		"l": {1: "...yKKKKy...", 2: "...KYwwYK...", 3: "...KwwwwK...", 4: "...KYwwYK...", 9: "b..bbbbbb..b"},
	},
	"h_ranger": {
		"b": {3: "..teeeeeet.."},
		"l": {4: "..teeeeeyyyy", 5: "..teeeeeeyy.", 8: "tttteeeetttt", 9: "t..teeeet..t"},
	},
	"h_nightblade": {
		"b": {4: "..wwwwwwww.."},
		"l": {0: ".w........w.", 1: ".ww......ww.", 4: "..wrwwwwrw..", 11: "..PP....PPww"},
	},
	"h_alchemist": {
		"b": {1: ".nnnnnnnnnn."},
		"l": {4: ".nlkkkkkkln.", 5: "..nnrrrrnn..", 6: "..ttttttttcC", 7: ".nttettettCw"},
	},
	"h_berserker": {
		"b": {4: "...wwwwww..."},
		"l": {4: "...wrwwrw...", 6: "....wrrw....", 8: "srrrRrrRrrrs", 9: "s..rrrrrr..s"},
	},
	"h_engineer": {
		"b": {0: ".....R......", 4: "..gGccGccg.."},
		"l": {0: "....ryr.....", 4: "..gGwCGwCg..", 8: "ggoobooboogg", 9: "g..oooooo..g"},
	},
	"h_wildheart": {
		"b": {7: "...eeeeee..."},
		"l": {8: "...eekkee...", 9: ".lleeeeeell."},
	},
	# ---- foes ----
	"slime": {
		"b": {4: "nnnnnnnnnnnn", 5: "nnnkknnkknnn"},
		"l": {6: "nnnnkkkkknnn", 7: "NnnnkwwwknnN"},
	},
	"bat": {
		"b": {0: "............", 1: "....PPPP...."},
		"l": {3: "PPPpwpwpPPPP", 6: "....pwwp...."},
	},
	"goblin": {
		"b": {3: ".nnkknkkn."},
		"l": {0: "ll......ll", 5: "..nkwwkn..", 7: "nntteettnn"},
	},
	"boar": {
		"b": {2: "tttttttttttrt.", 7: ".tt.tt...tt.tt"},
		"l": {2: "tttttttttttrt.", 3: "ttttTtttttttSS", 4: "tttttTttttwSSS"},
	},
	"shroom": {
		"b": {7: "...eeeeee..."},
		"l": {1: "..pmwpppmw..", 3: "pmpppwpppmpp", 8: "...eekkee..."},
	},
	"imp": {
		"b": {3: ".rrkkrkkr."},
		"l": {0: "yy......yy", 5: "..rkwwkr..", 6: "..rkyykr.."},
	},
	"mage": {
		"b": {4: ".pPkkkkkp."},
		"l": {4: ".pPwkkwkp.", 6: "..pPyyPp..", 7: "spppppppps", 8: ".pppYYppp."},
	},
	"guard": {
		"b": {3: "..gGkkkkGg.."},
		"l": {3: "..gGwkkwGg..", 6: "rrgGGGGGGgrr", 7: ".rGGgyyGGGr."},
	},
	"turret": {
		"b": {2: "...cCCc...", 3: "..cCCCCc.."},
		"l": {0: "...cwwc...", 1: "...cwwc...", 2: "...cwwc...", 3: "..cCwwCc.."},
	},
	"skel": {
		"b": {3: ".wwwwwwww."},
		"l": {2: ".wrkwwkrw.", 3: ".wkrwwrkw.", 5: "..wkkkkw..", 9: "w..GwwG..w"},
	},
	"wisp": {
		"b": {3: ".cCCCCCCc."},
		"l": {3: ".cCwCCwCc.", 6: ".cCkwwkCc.", 7: ".cCCkkCCc."},
	},
	# ---- bosses ----
	"golem": {
		"b": {5: ".....gGkkkkGGkkkkGg....."},
		"l": {5: ".....gGkwwkGGkwwkGg.....", 8: "..ggg.gGkkkkkkkkGg.ggg..", 9: ".gGGGggGGkyyyykGGggGGGg."},
	},
	"tyrant": {
		"b": {6: "...rrrkkkkrrrrkkkkrrr..."},
		"l": {6: "...rrrkwwkrrrrkwwkrrr...", 9: "....rrkkkkkkkkkkkkrr....", 10: "....rrkyoyoyoyoyokrr....", 14: "RrrrrRRroyYwwYyorRRrrrrR"},
	},
	"lich": {
		"b": {6: "....wwkkkwwwkkkww....."},
		"l": {6: "....wwkwkwwwkwkww.....", 12: ".PppppppPCCCPppppppP..", 13: ".PpppppPcwwwcPpppppP..", 14: "..PppppPcwwwcPppppP...", 15: ".w..pppPPcccPPppp..w.."},
	},
	"queen_b": {
		"b": {8: ".ppmkkkmmmkkkmmmkkkmmpp."},
		"l": {8: ".ppmkrkmmmkrkmmmkrkmmpp.", 12: "pmmmmmkkkkkkkkkkkkmmmmmp", 13: "pmmmmmmkwkwkwkwkkmmmmmmp"},
	},
	"iron_b": {
		"b": {3: ".......gGyyyyyyGg.......", 8: "KgGGGgGGcccccccGGGgGGGgK"},
		"l": {3: ".......gGwkwwkwGg.......", 7: "KgGGGgGGGcCCCcGGGGgGGGgK", 8: "KgGGGgGGcwwwwwcGGGgGGGgK", 9: "KgGGGgGGGcCCCcGGGGgGGGgK", 10: "KgyYygGGGGGGGGGGGGgyYygK"},
	},
	"void_b": {
		"b": {5: "....PKKKrrrrrrrrKKKP....", 6: "....PKKKrwwwwwwrKKKP....", 7: "....PKKKrrrrrrrrKKKP...."},
		"l": {4: "....PKKKrrwwwwrrKKKP....", 5: "....PKKrrwwkkwwrrKKP....", 6: "....PKKrwwkrrkwwrKKP....", 7: "....PKKrrwwkkwwrrKKP....", 8: "....PKKKrrwwwwrrKKKP...."},
	},
	"rootking_b": {
		"b": {7: "...tteekkkeeeekkkeett..."},
		"l": {7: "...tteekwkeeeekwkeett...", 11: "..ttttekkkkkkkkketttt...", 12: ".tt.tttekwkwkwkettt.tt.."},
	},
	"wyrm_b": {
		"b": {5: "...rrrokkorrrrokkorrr..."},
		"l": {0: ".yy..................yy.", 5: "...rrrowyorrrrowyorrr...", 10: ".....RkkkkkkkkkkkkR.....", 11: ".....RkyoyoyoyoyokR....."},
	},
	"sentinel_b": {
		"b": {10: "....gGGkmmmmmmmmkGGg...."},
		"l": {3: "....C...cCwwwwCc...C....", 4: "...CwC.cCwwwwwwCc.CwC...", 9: "....gGGkkmYYYYmkkGGg....", 10: "....gGGkmYwwwwYmkGGg....", 11: "....gGGkkmYYYYmkkGGg....", 15: ".pPp....bBwwwwBb....yYy."},
	},
}

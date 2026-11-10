extends RefCounted
# Every sprite in the game is authored here as a character map and baked to textures at boot.

const D = preload("res://src/data.gd")

static var PAL = {
	"k": Color("16121d"), "K": Color("3a3346"), "g": Color("6b6779"), "G": Color("a8a7b8"), "w": Color("f6f2e6"),
	"r": Color("d43b42"), "R": Color("8c2136"), "o": Color("f2812f"), "y": Color("ffd24a"), "Y": Color("fff2ae"),
	"b": Color("3f76dc"), "B": Color("283f8e"), "c": Color("5cd3f2"), "C": Color("c6f4ff"),
	"n": Color("4fae4c"), "N": Color("2b6a40"), "l": Color("a9e150"),
	"p": Color("9352cb"), "P": Color("55307f"), "m": Color("e56db2"),
	"s": Color("f3bb8e"), "S": Color("c88560"), "t": Color("8b5b3b"), "T": Color("553423"), "e": Color("c99b5c"),
}
static var OUT = Color("120e18")

static var T = {}  # name -> ImageTexture
static var W = {}  # name -> white silhouette texture (hit flash)
static var I = {}  # name -> Image
static var tiles = []  # per biome: {floor: [Image], face: [Image]}

const MAPS = {
	"h_warden": """
.....rr.....
....GGGGr...
...GwGGGGG..
..GwGGGGGGg.
..GGGkkkkkg.
..GGGkckkcg.
..GGGGGGGGg.
...gGGGGgg..
..BbbbbbbB..
.GBbbyybbBG.
.GBbbbbbbBG.
..BBbbbbBB..
..gg....gg..
..KK....KK..""",
	"h_arcanist": """
......pp....
.....pppP...
....ppppP...
...pppppPP..
..yyyyyyyyy.
.PpppppppppP
..SsskssksS.
..Ssssssss..
...pppppp...
..ppPyyPpp..
.spppppppps.
..pppppppp..
..PppppppP..
..PP....PP..""",
	"h_ranger": """
....nnnn....
...nnnnnn...
..nnNNNNnn..
..nNsssssn..
..nNskssks..
..nNssssss..
...nNssss...
..tnnnnnnt..
.snnNttNnns.
..nnnttnnn..
..NnnnnnnN..
..tt....tt..
..TT....TT..""",
	"h_nightblade": """
....KKKK....
...KKKKKK...
..KKKKKKKK..
..KKgggggK..
..KKwkgwkK..
..KKKKKKKK..
...rrrrrr.r.
..KKKrrKKrr.
.gKKKKKKKKg.
..KKKmmKKK..
..KKKKKKKK..
..KK....KK..
..gg....gg..""",
	"slime": """
....llll....
..llnnnnll..
.lnwnnnnnnl.
.nnwnnnnnnn.
nnnnknnnknnn
nnnnknnnknnn
nnnnnnnnnnnn
NnnnnnnnnnnN
.NNNNNNNNNN.""",
	"bat": """
P..........P
PP..PPPP..PP
PPPPpppPPPPP
PPPprprpPPPP
.PPPppppPPP.
..P.pwwp.P..
....p..p....""",
	"goblin": """
l........l
ll.nnnn.ll
.lnnnnnnl.
.nnwknwkn.
.nnnnnnnn.
..nNkkNn..
..tttttt..
.ntteettn.
.nttttttn.
..TTTTTT..
..NN..NN..
..NN..NN..""",
	"boar": """
..tt......tt..
.ttttttttttt..
tttttttttttkt.
ttttTttttttttS
tttttTttttwtSS
ttttttttttttt.
.ttttttttttt..
.tt.tt..tt.tt.
.TT.TT..TT.TT.""",
	"shroom": """
...pppppp...
..pmppppmp..
.pppmmppppp.
pmpppppppmpp
pppppmpppppp
.PPPPPPPPPP.
...eeeeee...
...ekeeke...
...eeeeee...
...eSSSSe...""",
	"imp": """
y........y
ry.rrrr.yr
.rrrrrrrr.
.rrykrykr.
.rrrrrrrr.
..rRwwRr..
..rrrrrr..
.rrRrrRrr.
..rrrrrr..
..RR..RR..
..RR..RR..""",
	"mage": """
...pppp...
..pppppp..
.ppPPPPpp.
.pPkkkkPp.
.pPykkykp.
.pPkkkkPp.
..pPPPPp..
.pppppppp.
spppyyppps
.pppppppp.
.pppppppp.
PppppppppP
PPPPPPPPPP""",
	"guard": """
...gggggg...
..gGGGGGGg..
..gGkkkkGg..
..gGokkoGg..
..gGGGGGGg..
...gggggg...
.rgGGGGGGgr.
.rGGgooGGGr.
.rGGGGGGGGr.
..gGGGGGGg..
..gg....gg..
..KK....KK..""",
	"turret": """
....cc....
...cCCc...
...cCwc...
..cCCwCc..
..cCCCCc..
..bcCCcb..
...bccb...
...gbbg...
..gGGGGg..
.gGGggGGg.
.gggggggg.
.KKKKKKKK.""",
	"skel": """
..wwwwww..
.wwwwwwww.
.wkkwwkkw.
.wkkwwkkw.
.wwwkkwww.
..wkwkww..
...wwww...
.GwGwwGwG.
..wGwwGw..
.w.GwwG.w.
...wwww...
..ww..ww..
..GG..GG..""",
	"wisp": """
...cccc...
..cCCCCc..
.cCCCCCCc.
.cCkCCkCc.
.cCkCCkCc.
.cCCCCCCc.
.cCCwwCCc.
.cCCCCCCc.
.ccCCCCcc.
.c.cc.cc.c
....c..c..""",
	"golem": """
........gggggggg........
......ggGGGGGGGGgg......
.....gGGGGGGGGGGGGg.....
.....gGGnnGGGGGGnGGg....
.....gGkkkkGGkkkkGg.....
.....gGkyykGGkyykGg.....
.....gGkkkkGGkkkkGg.....
.....gGGGGGGGGGGGGg.....
..ggg.gGGkkkkkkGGg.ggg..
.gGGGggGGGGGGGGGGggGGGg.
gGGGGGgGGnnGGGGGGgGGGGGg
gGGnGGgGGGnGGGGGGgGGGGGg
gGGGGGgGGGGGGGnnGgGGnGGg
gGGGGGgGGGGGGGGnGgGGGGGg
.gGGGg.gGGGGGGGGg.gGGGg.
.gGGGg.gGGGGGGGGg.gGGGg.
.gGGGg.gggggggggg.gGGGg.
.gggg..gGGg..gGGg..gggg.
.KKKK..gGGg..gGGg..KKKK.
.......gGGg..gGGg.......
......gGGGg..gGGGg......
......KKKKK..KKKKK......""",
	"tyrant": """
..y..................y..
.yo..................oy.
.or.....rrrrrrrr.....ro.
.orr..rrrrrrrrrrrr..rro.
..orrrrrrrrrrrrrrrrrro..
...rrrrkkrrrrrrkkrrrr...
...rrrkyykrrrrkyykrrr...
...rrrrkkrrrrrrkkrrrr...
...rrrrrrrrrrrrrrrrrr...
....rrwkwkwkwkwkwkrr....
....rrkwkwkwkwkwkwrr....
.....rrrrrrrrrrrrrr.....
..RRR.RRrrrrrrrrRR.RRR..
.RrrrRRrroooooorrRRrrrR.
RrrrrRRrooyyyyoorRRrrrrR
RrrrrR.rooyyyyoor.RrrrrR
.Rrrr..rroooooorr..rrrR.
.yyy...RrrrrrrrrR...yyy.
.......Rrrr..rrrR.......
.......Rrrr..rrrR.......
......RRrrr..rrrRR......
......kkkkk..kkkkk......""",
	"lich": """
......y...y...y.......
......yy.yyy.yy.......
......yyyyyyyyy.......
.....wwwwwwwwwww......
....wwwwwwwwwwwww.....
....wwkkkwwwkkkww.....
....wwkckwwwkckww.....
....wwkkkwkwkkkww.....
.....wwwwwkwwwww......
......wkwkwkwkw.......
..PP..pwwwwwwwp..PP...
.PppPpppppppppppPppP..
.PppppppPcccPppppppP..
.PpppppPcCwCcPpppppP..
..PppppPcCCCcPppppP...
..w.pppPPcccPPppp.w...
....ppppPPPPPpppp.....
....pppppppppppppp....
...PpppPpppppPpppP....
...Ppp.PpppppP.ppP....
....P...PpppP...P.....
..........PP..........""",
	"pistol": """
gGGGGGc.
gGGGGGGc
tt.g....
tt......""",
	"kunai": """
.....GG...
tt.GGwwGG.
ttcGwwwwwG
tt.GGwwGG.
.....GG...""",
	"rifle": """
..gGGGGGGGGGG
ttgGGcCcGGGk.
tttgg.g......
.tt..........""",
	"cannon": """
..KggggggggK
.KgGGGGGGGGc
ttgGGcCcGGGc
ttKggggggggK
.tt.........""",
	"staff": """
...........cc.
..........cCCc
ttttttttttcCwc
..........cccc
...........cc.""",
	"blade": """
..y............
..yGGGGGGGGGGc.
ttyCwwwwwwwwwwc
..yGGGGGGGGGGc.
..y............""",
	"bow": """
.tt...
w.tt..
w..tt.
w...t.
w...tt
wGGGGc
w...tt
w...t.
w..tt.
w.tt..
.tt...""",
	"coin": """
.yyyy.
yYYyyo
yYyyyo
yyyyyo
yyyyoo
.oooo.""",
	"orb": """
..C..
.Ccc.
Cccbb
.cbb.
..b..""",
	"heart": """
.rr.rr.
rmrrrrr
rrrrrrr
.rrrrR.
..rrR..
...R...""",
	"chest": """
.tttttttttttt.
tteeeeeeeeeett
teeeeeeeeeeeet
tttttttttttttt
yyyyyykkyyyyyy
teeeeekkeeeeet
teeeeeeeeeeeet
teeeeeeeeeeeet
tTTTTTTTTTTTTt""",
	"chest_open": """
.tttttttttttt.
tkkkkkkkkkkkkt
tkkYkkkkkYkkkt
tttttttttttttt
yyyyyyyyyyyyyy
teeeeeeeeeeeet
teeeeeeeeeeeet
tTTTTTTTTTTTTt""",
	"potion": """
..ww..
..GG..
.GrrG.
GrrrrG
GrwrrG
GrrrrG
.GGGG.""",
	"cell": """
.yyyy.
gGGGGg
gcCccg
gcCccg
gcCccg
gGGGGg
.gggg.""",
	"tome": """
.pppppp.
pPppppPp
pPpyypPp
pPpyypPp
pPppppPp
pwwwwwwp
.PPPPPP.""",
	"crate": """
tttttttttttt
teeeeeeeeeet
teTeeeeeeTet
teeTeeeeTeet
teeeTeeTeeet
teeeeTTeeeet
teeeeTTeeeet
teeeTeeTeeet
teeTeeeeTeet
teTeeeeeeTet
teeeeeeeeeet
tttttttttttt""",
	"barrel": """
..gggggg..
.gGGGGGGg.
gKKKKKKKKg
gggggggggg
gccccccccg
gccCcccccg
gccccccccg
gggggggggg
gKKKKKKKKg
gggggggggg
.gggggggg.""",
	"torch": """
.tt.
tttt
.tt.
.TT.
.TT.""",
	"dummy": """
..eeee..
.eeeeee.
.ekeeke.
.eeeeee.
..eeee..
tttttttt
..eeee..
..erre..
..eeee..
...tt...
...tt...
..TTTT..""",
	"cat": """
o...o....
oo.oo....
ooooo...o
okoko...o
ooooooo.o
.oooooooo
.oooooooo
.oo..oo..""",
	"jukebox": """
.pppppppp.
pPyyyyyyPp
pPyKKKKyPp
pPyKccKyPp
pPyKKKKyPp
pPyyyyyyPp
pPPPPPPPPp
prPbPyPnPp
pPPPPPPPPp
pGGGGGGGGp
pGkGkGkGGp
pPPPPPPPPp
.PP....PP.""",
	"tomb": """
..gggg..
.gGGGGg.
gGGGGGGg
gGkkkkGg
gGGGGGGg
gGkkkGGg
gGGGGGGg
gGGGGGGg
gggggggg
NnNnnNnN""",
	"altar": """
....pppppp....
...pPmmmmPp...
...pPmYYmPp...
....pPPPPp....
.gggggggggggg.
gGGGGGGGGGGGGg
gGgGGgGGgGGgGg
gggggggggggggg
.KKKKKKKKKKKK.""",
	"anvil": """
gGGGGGGGGGG.
.gGGGGGGGGGg
..gggggggg..
....gGGg....
....gGGg....
...gGGGGg...
..gggggggg..
..KKKKKKKK..""",
	"cauldron": """
.KKKKKKKK.
KnlnnlnnlK
KKKKKKKKKK
.KgKKKKgK.
.KKKKKKKK.
.KKKKKKKK.
..KKKKKK..
.K......K.""",
	"crystal": """
..cc..
.cCCc.
.cCwc.
cCCCCc
cCCwCc
cCCCCc
.cCCb.
.bccb.
gGGGGg
gggggg""",
	"fountain": """
.....cCCc.....
......cc......
..gggggggggg..
.gGccccccccGg.
gGcCccccccCcGg
gGGccccccccGGg
.gGGGGGGGGGGg.
..gggggggggg..""",
	"pet_pup": """
o.....o.
oo...oo.
ooooooo.
oykoyko.
ooowwoo.
.ooooo.y
.o...o.o""",
	"pet_owl": """
.c...c..
cCcccCc.
cwkCkwc.
cCCyCCc.
cCCCCCc.
.cCCCc..
..y.y...""",
	"pet_mote": """
..y.y...
.yYYYy..
yYwYwYy.
.YYYYY..
yYYYYYy.
.yYYYy..
..y.y...""",
	"pet_toad": """
.nn..nn.
nwknnwkn
nnnnnnnn
nllllllN
nnnnnnnN
.NN..NN.""",
	"ic_fire": """
...o...
..oo...
.ooyo..
.oyyo.o
ooyYyoo
oyYYYyo
.oyyyo.""",
	"ic_ice": """
...C...
.C.c.C.
..ccc..
CccwccC
..ccc..
.C.c.C.
...C...""",
	"ic_bolt": """
....yy.
...yy..
..yy...
.yyyyy.
...yy..
..yy...
.yy....""",
	"ic_tox": """
...l...
..lll..
..lnl..
.llnll.
.lnnnl.
.lnnnl.
..lll..""",
	"gem": """
.mmmm.
mYmmmp
mmmmpp
.mmpp.
..pp..""",
	"h_alchemist": """
....wwww....
...wwwwww...
..wwwwwwww..
..wsssssssw.
..ykcyykcy..
..ssssssss..
...sssSss...
..nnnnnnnn..
.snnlnnlnns.
..nnnyynnn..
..NnnnnnnN..
..tt....tt..
..TT....TT..""",
	"h_berserker": """
.w........w.
.ww.rrrr.ww.
..wrrrrrrw..
..rrrrrrrr..
..rsssssss..
..rskssksr..
..sssrrsss..
...srrrrs...
.tSssssssSt.
.sSsttttsSs.
..ttttyttt..
..tttttttt..
..SS....SS..
..TT....TT..""",
	"sk_whirl": """
...wwww...
..w....w..
.w..ww..w.
.w.w..w.w.
.w.w.ww.w.
.w.w....w.
.w..wwww..
..w.......
...wwwww..""",
	"sk_nova": """
....w.....
.w..w..w..
..w.w.w...
...www....
wwwwGwwww.
...www....
..w.w.w...
.w..w..w..
....w.....""",
	"sk_volley": """
.w...w...w
www.www.ww
.w...w...w
.w...w...w
.w...w...w
.G...G...G
.G...G...G""",
	"sk_blink": """
G..G..w...
.G..G..w..
..G..G..w.
GGGGGGwwww
..G..G..w.
.G..G..w..
G..G..w...""",
	"sk_bulwark": """
wwwwwwwww.
wGGGwGGGw.
wGGGwGGGw.
wwwwwwwww.
wGGGwGGGw.
.wGGwGGw..
..wGwGw...
...www....
....w.....""",
	"sk_rift": """
...wwww...
..w....w..
.w..GG..w.
w..G..G..w
w.G.ww.G.w
w..G..G..w
.w..GG..w.
..w....w..
...wwww...""",
	"sk_mines": """
......w...
.....w.w..
....G.....
..wwww....
.wwwwww...
wwGwwwww..
wwwwwwww..
.wwwwww...
..wwww....""",
	"sk_knives": """
w...w...w.
w...w...w.
.w..w..w..
.w..w..w..
..w.w.w...
..w.w.w...
...GGG....
...GGG....
....G.....""",
	"sk_transmute": """
...www....
....w.....
....w.....
...w.w....
..w...w...
.wGGGGGw..
wGGwGGGGw.
wGGGGwGGw.
.wwwwwww..""",
	"sk_elixir": """
...ww.....
...GG.....
..wwww....
.w....w...
w..ww..w..
w.wwww.w..
w..ww..w..
.w....w...
..wwww....""",
	"sk_leap": """
....w.....
....w.....
....w.....
..w.w.w...
...www....
....w.....
..........
w.GGGGG.w.
.wwwwwww..""",
	"sk_rage": """
w.......w.
.w.....w..
..wwwww...
.wwwwwww..
.wGwwwGw..
.wwwwwww..
.w.w.w.w..
..wwwww...""",
	"br_0": """
....w..
...ww..
..www..
.wwww..
..www.G
...wGG.
...GG..""",
	"br_1": """
wwwwwww
.w...w.
..wGw..
...w...
..w.w..
.wGGGw.
wwwwwww""",
	"br_2": """
...w...
..www..
w.www.w
wwwGwww
w.www.w
..www..
...w...""",
	"loom": """
..pp....pp..
.pmmp..pmmp.
.pmYp..pYmp.
..pp.cc.pp..
..t.cCCc.t..
..t.cCwc.t..
..t..cc..t..
.gttttttttg.
gGGGGGGGGGGg
gggggggggggg
.KKKKKKKKKK.""",
	"queen_b": """
.........y..y..y........
.........yyyyyyy........
........pppppppp........
......pppmmmmmmppp......
....pppmmwmmmmmmmppp....
...ppmmmwwmmmmmmmmmpp...
..ppmmmmmmmmmmmmmmmmpp..
..pmmkkmmmmkkmmmmkkmmp..
.ppmkwkmmmkwkmmmkwkmmpp.
.pmmkkkmmmkkkmmmkkkmmmp.
.pmmmmmmmmmmmmmmmmmmmmp.
ppmmmmmkkkkkkkkkkmmmmmpp
pmmmmmkwkwkwkwkwkkmmmmmp
pmmmmmmkkkkkkkkkkmmmmmmp
pmmmlmmmmmmmmmmmmmmlmmmp
ppmmmmmmmmmlmmmmmmmmmmpp
.ppmmmmmmmmmmmmmmmmmmpp.
..PPppppppppppppppppPP..
...PPPPPPPPPPPPPPPPPP...""",
	"iron_b": """
........gggggggg........
.......gGGGGGGGGg.......
.......gGyyyyyyGg.......
.......gGykyykyGg.......
.......gGGGGGGGGg.......
..KKK...gggggggg...KKK..
.KgggKgGGGGGGGGGGgKgggK.
KgGGGgGGGcccccGGGGgGGGgK
KgGGGgGGcCCCCCcGGGgGGGgK
KgGGGgGGGcccccGGGGgGGGgK
KgyyygGGGGGGGGGGGGgyyygK
.KgggKgGGGGGGGGGGgKgggK.
.KkkkK.gggggggggg.KkkkK.
.KkkkK..gGGggGGg..KkkkK.
..KKK...gGGg.gGGg..KKK..
........gGGg.gGGg.......
.......gGGGg.gGGGg......
.......KKKKK.KKKKK......""",
	"void_b": """
.........PPPPPP.........
.......PPKKKKKKPP.......
......PKKKKKKKKKKP......
.....PKKKKKKKKKKKKP.....
....PKKKKrrrrrrKKKKP....
....PKKKrrwwwwrrKKKP....
....PKKKrwwkkwwrKKKP....
....PKKKrrwwwwrrKKKP....
....PKKKKrrrrrrKKKKP....
...PPKKKKKKKKKKKKKKPP...
..PKKKKKKKKKKKKKKKKKKP..
.PKKKPKKKKKKKKKKKKPKKKP.
.PKKP.PKKKKKKKKKKP.PKKP.
.PKP..PKKKKKKKKKKP..PKP.
..P...PKKPKKKKPKKP...P..
......PKP.PKKP.PKP......
......PP..PKKP..PP......
..........PKKP..........
...........PP...........""",
	"key": """
.yyy..
y...y.
y...y.
.yyy..
..y...
..yy..
..y...
..yy..""",
	"relic": """
..yyyy..
.yccccy.
ycCCcccy
ycCwcccy
yccccbby
.ycbbby.
..yyyy..""",
	"board": """
tttttttttttt
teeeeeeeeeet
tewwwewwwwet
teeeeeeeeeet
tewwwwwewwet
teeeeeeeeeet
tewwewwwweet
tttttttttttt
....tt......
....tt......
...TTTT.....""",
	"shelf": """
tttttttttttt
trrbbnnyppmt
trrbbnnyppmt
tttttttttttt
tccyyrrbbnnt
tccyyrrbbnnt
tttttttttttt
tppmmccnnyyt
tppmmccnnyyt
tttttttttttt
TT........TT""",
	"plot": """
.TTTTTTTTTT.
TtTttTtTttTT
TttTtttTtTtT
.TTTTTTTTTT.""",
	"sprout": """
..n..n..
.nlnnln.
..nnnn..
...nn...
...nn...""",
	"plant": """
..cC.cC.
.cCCcCCc
..cc.cc.
.n.nn.n.
.nnnnnn.
..nNNn..
...nn...
...nn...""",
	"chest_lock": """
.gggggggggggg.
ggGGGGGGGGGGgg
gGGGGGGGGGGGGg
gggggggggggggg
yyyyyykkyyyyyy
gGGGGykkyGGGGg
gGGGGGyyGGGGGg
gGGGGGGGGGGGGg
gKKKKKKKKKKKKg""",
	"trophy": """
yyyyyyyy
yYYyyyyo
.yYyyyo.
.yyyyyo.
..yyyo..
...yo...
...yo...
..tttt..
.tTTTTt.""",
	"capsule": """
.gggggggg.
gCCCCCCCCg
gCrCyCbCCg
gCCnCCmCCg
gCyCCrCnCg
gggggggggg
gppppppppg
gppkkkkppg
gppkYYkppg
gppppppppg
gPPPPPPPPg
.gg....gg.""",
	"rack": """
tttttttttttt
t.G..c..y..t
t.G..c..y..t
t.G..c..y..t
t.G..C..y..t
t.t..t..t..t
tttttttttttt
t..........t
TT........TT""",
	"mailbox": """
.bbbbbb.
bBBBBBBb
bBwwwwBb
bBBBBBBr
bbbbbbbr
...tt...
...tt...
...tt...
..TTTT..""",
	"mannequin": """
...ee...
..eeee..
...ee...
.mmmmmm.
mmmmmmmm
.mmmmmm.
.mmmmmm.
..mmmm..
...tt...
...tt...
..TTTT..""",
	"axe": """
.........GGG.
........GcCCG
tttttttttGCCG
........GcCCG
.........GGG.""",
	"greatblade": """
...y.............
..yyGGGGGGGGGGGc.
ttyyCwwwwwwwwwwwc
ttyyCwwwwwwwwwwwc
..yyGGGGGGGGGGGc.
...y.............""",
	"shotgun": """
.KggggggggggK
.gGGGGGGGGGGc
ttgGGGGGGGGGc
tttKggg......
.tt..........""",
	"smg": """
..gGGGGGGGGc
ttgGcCGGGGk.
ttgggg.g....
.tt..gg.....""",
	"sprayer": """
..KKKK.......
.gGGGGgggggc.
ttGcCGGGGGGCc
ttgGGGggggc..
.tt.KK.......""",
	"coil": """
.........c.c..
........cCcCc.
tttttttttCwC..
........cCcCc.
.........c.c..""",
	"mortar": """
...KggggggK.
..gGGGGGGGGc
ttgGcCcGGGGc
tt.KggggggK.
ttt.........""",
	"flask": """
....ww..
...GccG.
tt.GcCcG
ttGccCcG
...GccG.
....GG..""",
	"railgun": """
..gggggggggggggg.
.gGGcGGcGGcGGcGGc
ttgKKKKKKKKKKKKK.
ttgGGcGGcGGcGGcGc
.tt.gggggggggggg.""",
	"lance": """
..gGGGGGGGg....
ttgGcCCCCCCCCCw
ttgGGGGGGGg....
.tt............""",
	"starstaff": """
...........y..
..........cCc.
ttttttttttCwCy
..........cCc.
...........y..""",
	"rootking_b": """
....n...n..nn..n...n....
...nln.nlnnllnnln.nln...
....nnnnnnnnnnnnnnnn....
.....tttttttttttttt.....
....tteeeeeeeeeeeett....
...tteeTeeeeeeeeTeett...
...tteekkkeeeekkkeett...
...tteekykeeeekykeett...
...tteekkkeeeekkkeett...
...tteeeeeeTTeeeeeett...
...ttTeeekkkkkkeeeTtt...
..tttteekwkwkwkeetttt...
.tt.ttteekkkkkeettt.tt..
tt..tttteeeeeeetttt..tt.
t...ttttttttttttttt...t.
...tttTtttttttttTttt....
..ttt.ttt.tttt.ttt.ttt..
.tt...tt...tt...tt...tt.
.T....T....TT....T....T.""",
	"wyrm_b": """
..y..................y..
..yy................yy..
...oy..rrrrrrrrrr..yo...
...oorrrrrrrrrrrrrroo...
....rrroorrrrrroorrr....
...rrrokyorrrrokyorrr...
...rrroooorrrroooorrr...
...rrrrrrrrrrrrrrrrrr...
....rrrrkrrrrrrkrrrr....
....RrrrrrrrrrrrrrrR....
.....RwkwkwkwkwkwkR.....
.....RkwkwkwkwkwkwR.....
......RRrrrrrrrrRR......
..rrrr..RRrrrrRR..rrrr..
.rroorr...rrrr...rroorr.
.rooyor..rroorr..royoor.
.rroorrrrrooyorrrrroorr.
..rrrrRRrrroorrrRRrrrr..
....RRR..rrrrrr..RRR....""",
	"sentinel_b": """
...........cc...........
..........cCCc..........
.........cCCCCc.........
....c...cCCwwCCc...c....
...cCc.cCCwwwwCCc.cCc...
...cCc.cCCCCCCCCc.cCc...
....c.gggggggggggg.c....
.....gGGGGGGGGGGGGg.....
....gGGGkkkkkkkkGGGg....
....gGGkkmmmmmmkkGGg....
....gGGkmmYwwYmmkGGg....
....gGGkkmmmmmmkkGGg....
....gGGGkkkkkkkkGGGg....
.....gGGGGGGGGGGGGg.....
..p...gggggggggggg...y..
.pPp....bBBBBBBb....yYy.
..p......bBBBBb......y..
..........bBBb..........
...........bb...........""",
	"crossbow": """
....t.....
...tGGGGGc
tttttttttC
...tGGGGGc
....t.....""",
	"boomerang": """
.cCCCCCc.
cCc...cCc
Cc.....cC
c.......c""",
	"twins": """
gGGGGc..
tt......
..gGGGGc
..tt....""",
	"spear": """
..............c.
tttttttttttttGCc
..............c.""",
	"hammer": """
.........gGGGg
.........gcCCg
tttttttttgCCCg
.........gcCCg
.........gGGGg""",
	"chakram": """
..cCCc..
.c....c.
C..GG..C
C..GG..C
.c....c.
..cCCc..""",
	"grimoire": """
.pppppp.
pPcCCcPp
pPCwwCPp
pPcCCcPp
pwwwwwwp
.PPPPPP.""",
	"launcher": """
.KggggggggggK.
gGGGGGGGGGGGcC
ttgGGcCcGGGGcC
ttKggggggggK..
.tt...........""",
	"h_engineer": """
...yyyyyy...
..yyyyyyyy..
.yyyyyyyyyy.
..sGcsscGs..
..ssssssss..
...ssSSss...
..tttttttt..
.sttGttGtts.
..ttyttytt..
..tttttttt..
..bb....bb..
..KK....KK..""",
	"h_wildheart": """
..n......n..
..nt.nn.tn..
...tnnnnt...
..nnnnnnnn..
..nsssssss..
..nskssksn..
..nssssssn..
...lnnnnl...
.snnllllnns.
..nnnttnnn..
..NnnnnnnN..
..ee....ee..
..TT....TT..""",
	"sk_turret": """
....ww....
...wGGw...
...wGGw...
..wwwwww..
..wGGGGw..
.wwwwwwww.
.w......w.""",
	"sk_pulse": """
...wwww...
..w....w..
.w..GG..w.
.w.GwwG.w.
.w..GG..w.
..w....w..
...wwww...""",
	"sk_vines": """
.w......w.
..w.ww.w..
...wGGw...
..w.GG.w..
.w..GG..w.
....GG....
...wGGw...""",
	"sk_spirits": """
..ww......
.wGGw..ww.
.wGGw.wGGw
..ww..wGGw
....ww.ww.
...wGGw...
...wGGw...""",
	"bench": """
.ttttttttttttt.
teeeeeeeeeeeeet
teGGeeeeeycceet
ttttttttttttttt
.tT.........Tt.
.tT..gGGg...Tt.
.tT..gggg...Tt.
.TT.........TT.""",
	"blueprint": """
.bbbbbbbb.
bBccccccBb
bBcwwcCcBb
bBcCcwwcBb
bBccccccBb
.bbbbbbbb.""",
	"scrap": """
.g.gg.g.
gGGGGGGg
.GGkkGG.
gGGkkGGg
.GGGGGG.
g.gg.g..""",
	"m_ore": """
..gGg..
.gGGGg.
gGcGGGg
gGGGcGg
.gGGGg.""",
	"m_ess": """
..m..
.mYm.
mYwYm
.mYm.
..m..""",
	"m_fib": """
n...n.
.n.n..
.lnl..
..n...
.eee..
..e...""",
	"seed": """
..n..
.ee..
eeTe.
eTee.
.ee..""",
	"bowl": """
..rrrr....
.rmrrmr...
gggggggggg
.gGGGGGGg.
..gggggg..""",
	"treat": """
.n...
rrr..
rmrr.
rrrr.
.rr..""",
	"pedestal": """
.GGGGGGGGGG.
GwGGGGGGGGGG
gggggggggggg
.gKKKKKKKKg.
.gggggggggg.""",
}

const WSPR = ["pistol", "kunai", "rifle", "cannon", "staff", "blade", "bow", "axe", "greatblade", "shotgun", "smg", "sprayer", "coil", "mortar", "flask", "railgun", "lance", "starstaff", "crossbow", "boomerang", "twins", "spear", "hammer", "chakram", "grimoire", "launcher"]

# Texture name for a weapon. Fused weapons get both colours and gilded metal, built on demand.
static func wtex(w: Dictionary) -> String:
	var s: String = D.WEAPONS[w.id].spr
	var el2: String = w.get("el2", "")
	if el2 == "":
		return "w_%s_%s" % [s, w.el]
	var n = "w_%s_%s_%s" % [s, w.el, el2]
	if not T.has(n):
		var a = el_swap(w.el)
		var b = el_swap(el2)
		make(n, MAPS[s], {"c": a.get("c", "c"), "C": b.get("c", "c"), "b": b.get("b", "b"), "g": "e", "K": "T", "G": "Y"})
	return n

static func el_swap(el: String) -> Dictionary:
	match el:
		"fire": return {"c": "o", "C": "y", "b": "R"}
		"ice": return {}
		"bolt": return {"c": "y", "C": "Y", "b": "o"}
		"tox": return {"c": "n", "C": "l", "b": "N"}
		"prism": return {"c": "m", "C": "Y", "b": "p"}
	return {"c": "G", "C": "w", "b": "g"}

static func build() -> void:
	if not T.is_empty():
		return
	for h in D.HEROES:
		make("h_" + h.id, MAPS["h_" + h.id])
		walk_frames("h_" + h.id)
	for id in D.ENEMIES:
		var d = D.ENEMIES[id]
		make("e_" + id, MAPS[d.spr], d.get("swap", {}))
		if d.get("walk", false):
			walk_frames("e_" + id)
	for base in WSPR:
		for el in ["", "fire", "ice", "bolt", "tox", "prism"]:
			make("w_" + base + "_" + el, MAPS[base], el_swap(el))
	for n in ["coin", "orb", "heart", "chest", "chest_open", "potion", "cell", "tome", "crate", "torch", "pedestal"]:
		make(n, MAPS[n])
	for el in ["fire", "ice", "bolt", "tox"]:
		make("barrel_" + el, MAPS["barrel"], el_swap(el))
	for el in ["", "fire", "ice", "bolt", "tox"]:
		var c = D.EL_COL[el]
		reg("b_" + el, orb(3, c, c.darkened(0.45), Color.WHITE))
		reg("B_" + el, orb(5, c, c.darkened(0.45), Color.WHITE))
		reg("eb_" + el, orb(4, Color("ff4a5e") if el == "" else c, Color("2a0714"), Color("fff0d0")))
		reg("arrow_" + el, arrow(c))
	for n in ["sk_turret", "sk_pulse", "sk_vines", "sk_spirits", "sk_whirl", "sk_nova", "sk_volley", "sk_blink", "sk_bulwark", "sk_rift", "sk_mines", "sk_knives", "sk_transmute", "sk_elixir", "sk_leap", "sk_rage", "br_0", "br_1", "br_2", "loom"]:
		make(n, MAPS[n])
	for n in ["key", "board", "shelf", "plot", "sprout", "chest_lock"]:
		make(n, MAPS[n])
	for id in D.RELICS:
		var sw = D.RELICS[id].sw
		make("relic_" + id, MAPS["relic"], {"c": sw[0], "C": sw[1], "b": sw[2]})
	for id in D.SEEDS:
		make("plant_" + id, MAPS["plant"], D.SEEDS[id].sw)
	for n in ["m_ore", "m_ess", "m_fib", "seed", "bowl", "treat", "bench", "blueprint", "scrap", "trophy", "capsule", "rack", "mailbox", "mannequin"]:
		make(n, MAPS[n])
	make("npc_cook", MAPS["goblin"], {"t": "w", "e": "G", "T": "g"})
	make("npc_tailor", MAPS["mage"], {"p": "m", "P": "p"})
	make("npc_quarter", MAPS["guard"], {"r": "n", "o": "l"})
	for n in ["cat", "jukebox", "tomb", "altar", "anvil", "cauldron", "fountain", "pet_pup", "pet_owl", "pet_mote", "pet_toad", "ic_fire", "ic_ice", "ic_bolt", "ic_tox", "gem"]:
		make(n, MAPS[n])
	for el in ["fire", "ice", "bolt", "tox"]:
		make("crystal_" + el, MAPS["crystal"], el_swap(el))
	make("crystal_prism", MAPS["crystal"], el_swap("prism"))
	make("npc_mentor", MAPS["mage"], {"p": "b", "P": "B"})
	make("npc_armorer", MAPS["guard"], {"r": "y", "o": "y"})
	make("npc_keeper", MAPS["goblin"], {"t": "n", "e": "l", "T": "N"})
	make("npc_merchant", MAPS["goblin"], {"t": "p", "e": "y", "T": "P"})
	make("npc_smith", MAPS["guard"], {"r": "t", "G": "e", "g": "t"})
	make("npc_alch", MAPS["mage"], {"p": "n", "P": "N"})
	make("m_boar", MAPS["boar"])
	walk_frames("m_boar")
	make("m_strider", MAPS["boar"], {"t": "b", "T": "B", "S": "y", "w": "y"})
	walk_frames("m_strider")
	reg("light", light_tex())
	reg("shadow", shadow_tex())
	build_tiles()

static func make(name: String, src: String, swaps: Dictionary = {}) -> void:
	var rows = []
	for line in src.split("\n"):
		var s = line.strip_edges()
		if s != "":
			rows.append(s)
	var h = rows.size()
	var w = 0
	for r in rows:
		w = max(w, r.length())
	var img = Image.create_empty(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	for y in h:
		var r = rows[y]
		for x in r.length():
			var ch = r[x]
			if swaps.has(ch):
				ch = swaps[ch]
			if PAL.has(ch):
				img.set_pixel(x + 1, y + 1, PAL[ch])
	outline(img)
	reg(name, img)

static func outline(img: Image) -> void:
	var src = img.duplicate()
	var w = img.get_width()
	var h = img.get_height()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0:
				continue
			var hit = false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx = x + d.x
				var ny = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and src.get_pixel(nx, ny).a > 0.0:
					hit = true
					break
			if hit:
				img.set_pixel(x, y, OUT)

static func reg(name: String, img: Image) -> void:
	I[name] = img
	T[name] = ImageTexture.create_from_image(img)
	var wi = img.duplicate()
	for y in wi.get_height():
		for x in wi.get_width():
			if wi.get_pixel(x, y).a > 0.0:
				wi.set_pixel(x, y, Color.WHITE)
	W[name] = ImageTexture.create_from_image(wi)

# A woven hero: head of one base hero, body of another, cloth colours hue-shifted.
static var gen_done = {}

static func gen_hero(seed: int, name: String = "h_gen") -> void:
	if gen_done.get(name, -1) == seed:
		return
	gen_done[name] = seed
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	var n = D.HEROES.size()
	var a: String = D.HEROES[rng.randi() % n].id
	var b: String = D.HEROES[rng.randi() % n].id
	var shift = rng.randf_range(0.15, 0.85)
	for suf in ["", "_1", "_2"]:
		var ia: Image = I["h_" + a + suf]
		var ib: Image = I["h_" + b + suf]
		var img: Image = ia.duplicate()
		var h = img.get_height()
		var hb = ib.get_height()
		for y in 7:
			for x in img.get_width():
				img.set_pixel(x, h - 1 - y, ib.get_pixel(x, hb - 1 - y) if x < ib.get_width() else Color(0, 0, 0, 0))
		for y in h:
			for x in img.get_width():
				var c = img.get_pixel(x, y)
				# leave outline, greys and skin tones alone
				if c.a > 0.0 and c.s > 0.3 and c.v > 0.2 and not (c.h > 0.03 and c.h < 0.11 and c.s < 0.6):
					img.set_pixel(x, y, Color.from_hsv(fmod(c.h + shift, 1.0), c.s, c.v, 1.0))
		reg(name + suf, img)

# Sprite name for a player described by look = {k, a, b, seed}; builds fused and woven
# sprites on demand so both sides of a LAN game can draw any hero.
static func look(l: Dictionary) -> String:
	var names = []
	for id in [l.a, l.get("b", "")]:
		if id == "gen":
			var gn = "hg_%d" % int(l.seed)
			gen_hero(int(l.seed), gn)
			names.append(gn)
		else:
			names.append("h_" + id)
	var name: String = names[0]
	if l.k == "fuse":
		name = "hf_%s_%s" % [names[0], names[1]]
		if not T.has(name):
			fuse_hero(names[0], names[1], name)
	# tailor dye: shift the hue of the cloth, leave outline, greys and skin alone
	var dye = float(l.get("dye", 0.0))
	if dye <= 0.0:
		return name
	var dn = "%s_d%d" % [name, int(dye * 100.0)]
	if not T.has(dn):
		for suf in ["", "_1", "_2"]:
			var img: Image = I[name + suf].duplicate()
			for y in img.get_height():
				for x in img.get_width():
					var c = img.get_pixel(x, y)
					if c.a > 0.0 and c.s > 0.3 and c.v > 0.2 and not (c.h > 0.03 and c.h < 0.11 and c.s < 0.6):
						img.set_pixel(x, y, Color.from_hsv(fmod(c.h + dye, 1.0), c.s, c.v, 1.0))
			reg(dn + suf, img)
	return dn

# Character fusion: head of sprite a on the body and legs of sprite b.
static func fuse_hero(a: String, b: String, name: String) -> void:
	for suf in ["", "_1", "_2"]:
		var ia: Image = I[a + suf]
		var ib: Image = I[b + suf]
		var img: Image = ia.duplicate()
		var h = img.get_height()
		var hb = ib.get_height()
		for y in 7:
			for x in img.get_width():
				img.set_pixel(x, h - 1 - y, ib.get_pixel(x, hb - 1 - y) if x < ib.get_width() else Color(0, 0, 0, 0))
		for y in h:
			for x in img.get_width():
				if img.get_pixel(x, y).is_equal_approx(OUT):
					img.set_pixel(x, y, Color("7a5514"))
		reg(name + suf, img)

# Two extra frames with one foot lifted each, for a cheap walk cycle.
static func walk_frames(name: String) -> void:
	var base: Image = I[name]
	var w = base.get_width()
	var h = base.get_height()
	for f in 2:
		var img = base.duplicate()
		var x0 = 0 if f == 0 else w / 2
		var x1 = w / 2 if f == 0 else w
		for x in range(x0, x1):
			for y in range(h - 4, h - 1):
				img.set_pixel(x, y, base.get_pixel(x, y + 1))
			img.set_pixel(x, h - 1, Color(0, 0, 0, 0))
		reg(name + "_" + str(f + 1), img)

static func orb(r: int, col: Color, rim: Color, core: Color) -> Image:
	var s = r * 2 + 1
	var img = Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d = Vector2(x - r, y - r).length()
			if d <= r + 0.3:
				var c = rim
				if d <= r - 0.9:
					c = col
				if d <= r * 0.45:
					c = core
				img.set_pixel(x, y, c)
	return img

static func arrow(col: Color) -> Image:
	var img = Image.create_empty(9, 3, false, Image.FORMAT_RGBA8)
	for x in 9:
		img.set_pixel(x, 1, Color.WHITE if x > 5 else col)
	img.set_pixel(7, 0, col)
	img.set_pixel(7, 2, col)
	img.set_pixel(0, 0, col.darkened(0.3))
	img.set_pixel(0, 2, col.darkened(0.3))
	return img

static func light_tex() -> Image:
	var s = 96
	var img = Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d = Vector2(x - s / 2.0 + 0.5, y - s / 2.0 + 0.5).length() / (s / 2.0)
			var a = clamp(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a * (3.0 - 2.0 * a)))
	return img

static func shadow_tex() -> Image:
	var img = Image.create_empty(16, 6, false, Image.FORMAT_RGBA8)
	for y in 6:
		for x in 16:
			var d = Vector2((x - 7.5) / 8.0, (y - 2.5) / 3.0).length()
			if d <= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0.38))
	return img

# ---- dungeon tiles -------------------------------------------------------------

static func build_tiles() -> void:
	var rng = RandomNumberGenerator.new()
	for bi in D.BIOMES.size():
		var b = D.BIOMES[bi]
		rng.seed = 7700 + bi
		var fl = []
		for v in 10:
			fl.append(floor_tile(rng, b, bi, v))
		var fc = []
		for v in 4:
			fc.append(face_tile(rng, b, bi, v))
		tiles.append({"floor": fl, "face": fc})

static func floor_tile(rng: RandomNumberGenerator, b: Dictionary, bi: int, v: int) -> Image:
	var img = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var base: Color = b.floor[v % 3]
	img.fill(base)
	var hi = base.lightened(0.06)
	var lo = base.darkened(0.12)
	for i in 16:
		img.set_pixel(i, 0, hi)
		img.set_pixel(0, i, hi)
		img.set_pixel(i, 15, b.grout.lerp(base, 0.45))
		img.set_pixel(15, i, b.grout.lerp(base, 0.45))
	if bi == 0 and v % 2 == 1:
		# split flagstone
		var sx = 7 + rng.randi() % 3
		for y in 15:
			img.set_pixel(sx, y, b.grout)
			img.set_pixel(sx + 1, y, hi)
	if bi == 1:
		# riveted plate
		for c in [Vector2i(2, 2), Vector2i(12, 2), Vector2i(2, 12), Vector2i(12, 12)]:
			img.set_pixel(c.x, c.y, hi.lightened(0.1))
			img.set_pixel(c.x + 1, c.y + 1, lo)
	if bi == 2 and v % 2 == 0:
		# inlaid diamond
		for i in 4:
			img.set_pixel(7 - i, 4 + i, lo)
			img.set_pixel(8 + i, 4 + i, lo)
			img.set_pixel(7 - i, 11 - i, hi)
			img.set_pixel(8 + i, 11 - i, hi)
	for i in 5 + rng.randi() % 5:
		img.set_pixel(1 + rng.randi() % 14, 1 + rng.randi() % 14, lo if rng.randf() < 0.6 else hi)
	if v >= 7:
		# cracks, moss, lava seams or glowing runes depending on biome
		var p = Vector2i(2 + rng.randi() % 5, 2 + rng.randi() % 5)
		var acc: Color = b.accent
		for i in 9:
			img.set_pixel(clampi(p.x, 1, 14), clampi(p.y, 1, 14), b.grout if (bi == 0 and v == 7) else acc.darkened(0.25 if i % 3 else 0.0))
			if bi == 0 and v > 7:
				img.set_pixel(clampi(p.x + 1, 1, 14), clampi(p.y, 1, 14), acc.darkened(0.4))
			p += Vector2i(1 if rng.randf() < 0.7 else 0, 1 if rng.randf() < 0.6 else 0)
	return img

static func face_tile(rng: RandomNumberGenerator, b: Dictionary, bi: int, v: int) -> Image:
	var img = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var c0: Color = b.face[0]
	var c1: Color = b.face[1]
	var c2: Color = b.face[2]
	img.fill(c1)
	for row in 4:
		var y0 = row * 4
		var off = 0 if row % 2 == 0 else 4
		for x in 16:
			var shade = c0 if row < 2 else c1
			if row == 3:
				shade = c1.darkened(0.15)
			img.set_pixel(x, y0, shade.lightened(0.12) if row < 3 else shade)
			img.set_pixel(x, y0 + 1, shade)
			img.set_pixel(x, y0 + 2, shade)
			img.set_pixel(x, y0 + 3, c2)
			if (x + off) % 8 == 7:
				for k in 3:
					img.set_pixel(x, y0 + k, c2)
	for i in 3 + v:
		img.set_pixel(rng.randi() % 16, rng.randi() % 15, c2 if rng.randf() < 0.5 else c0.lightened(0.1))
	if v == 3:
		var acc: Color = b.accent
		for i in 4:
			img.set_pixel(5 + i, 5 + (i % 2), acc.darkened(0.2))
			img.set_pixel(6 + i, 9, acc.darkened(0.35))
	for x in 16:
		img.set_pixel(x, 15, c2.darkened(0.35))
	return img

# Debug: every sprite on one sheet.
static func sheet(scale: int = 4) -> Image:
	var out = Image.create_empty(1200, 900, false, Image.FORMAT_RGBA8)
	out.fill(Color("2a2438"))
	var x = 8
	var y = 8
	var rowh = 0
	var names = I.keys()
	for n in names:
		if n == "light":
			continue
		var im: Image = I[n].duplicate()
		im.resize(im.get_width() * scale, im.get_height() * scale, Image.INTERPOLATE_NEAREST)
		if x + im.get_width() > 1190:
			x = 8
			y += rowh + 8
			rowh = 0
		out.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(x, y))
		x += im.get_width() + 8
		rowh = max(rowh, im.get_height())
	var tx = 8
	for t in tiles:
		for im0 in t.floor + t.face:
			var im: Image = im0.duplicate()
			im.resize(16 * scale, 16 * scale, Image.INTERPOLATE_NEAREST)
			out.blit_rect(im, Rect2i(0, 0, 16 * scale, 16 * scale), Vector2i(tx, 900 - 70))
			tx += 16 * scale
	return out

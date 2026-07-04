# Dungeon Core: Elemental Rebirth — GDD Overview

2D pixel top-down roguelite dungeon crawler. Concept goc, khong sao chep asset/ten/he thong tu game khac.

## Design pillars
1. **Combat doc duoc:** moi don danh co telegraph >= 0.5s. Chet la do nguoi choi.
2. **Build da dang > chi so phong:** meta progression mo lua chon, khong mo sat thuong vo han (cap: +30% HP, +15% dmg).
3. **Run ngan, y nghia dai:** 1 run 20-35 phut, moi run deu dong gop tai nguyen meta.
4. **Nguyen to la ngon ngu chung:** vu khi, skill, bay, moi truong, quai deu tuong tac qua he nguyen to.

## Core loop
- **Micro (3-10s):** ne dan, dash (i-frame 0.2s), tan cong, kich hoat nguyen to, quan ly energy/mana.
- **Mid (1-3 phut/phong):** don phong -> chon cua (icon phan thuong) -> nang cap tam -> boss tang.
- **Macro (20-35 phut/run):** loadout o hub -> 3-5 tang -> chet/thang -> tai nguyen meta -> nang cap -> run moi.

**Quy tac chet:** mat vu khi/relic/potion trong run; giu 100% Soul Shard, Element Core, Rune Dust, Blueprint; giu 50% Gold.

## MVP scope (Vertical Slice)
- 3 class: Kiem si (Blade Warden), Phap su (Arcanist), Xa thu cung (Ranger)
- 1 biome: Hang Co (Ancient Cave), 3 tang, 2 boss
- 12 vu khi, 4 nguyen to (Lua/Bang/Set/Doc) + 6 combo
- 10 quai, 15 relic
- Hub toi gian: Dungeon Gate, Class Hall, Blacksmith, Training Ground
- Procedural gen v1 (xem `10-dungeon-gen.md`)

## Roadmap
| Giai doan | Thoi luong | Pham vi |
|---|---|---|
| MVP | 3-4 thang | Nhu tren |
| Alpha | +3 thang | +4 class, +3 biome, +4 boss, skill tree 6 class, Rune Workshop, Elemental Altar, Endless |
| Beta | +3 thang | Du 10 class, 5 hybrid, 8 biome, Daily Seed, Boss Rush, codex |
| 1.0 | +2-3 thang | 20 hybrid, 11 nguyen to + 30 combo, 10 boss, Hardcore, Elemental Chaos |
| Post-launch | - | Co-op, NG+, noi dung theo mua |

## KPI can bang MVP
- Run 20-35 phut; ti le thang nguoi moi sau 10 run: 15-25%
- TTK quai thuong 1-3s; boss fight 2-4 phut

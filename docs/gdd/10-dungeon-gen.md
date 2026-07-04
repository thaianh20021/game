# Procedural Dungeon Generation — Technical Spec

Graph-first, room-template-second. Moi random di qua `SeededRNG` de dam bao:
**cung seed + cung config -> map + spawn giong het 100%** (yeu cau cho Daily Seed mode).

## Module layout
```
scripts/dungeon_gen/
├── seeded_rng.gd     # Deterministic RNG (moi random PHAI di qua day)
├── room_node.gd      # Data class cho 1 phong
├── graph_builder.gd  # B1-3: sinh graph phong
├── validator.gd      # B9: kiem tra cau truc
└── (planned) room_stamper.gd, spawner.gd, boss_picker.gd
data/
├── enemies_ancient_cave.json
└── loot_tables.json
```

## Input / Output
- **Input (FloorConfig):** seed int64, biome, floor_index N, difficulty 1-5, modifiers[]
- **Output:** graph phong (RoomNode[]) + tilemap tung phong + spawn plan + boss

## Tham so tunable
| Tham so | Gia tri |
|---|---|
| So phong critical path | `8 + floor_index * 2` |
| So nhanh phu | 2-4 |
| Do dai nhanh | 1-3 phong, ket thuc bang phong thuong |
| Enemy budget/phong | `10 * (1 + 0.25*floor_index) * difficulty_mult` |
| Quota phong | shop=1, shrine=1, treasure=1-2, event=1, secret=0-1, miniboss=1, heal=1 (truoc boss) |
| Vi tri miniboss | 60-75% critical path |
| Pity loot | 10 phong khong Rare+ -> phong ke force Rare |

## Pipeline (9 buoc)
1. **Critical path:** sinh truoc Entrance -> ... -> Boss. Khong bao gio ket duong.
2. **Nhanh phu:** 2-4 nhanh gan vao giua path, ket thuc bang phong thuong. Secret noi bang "tuong nut".
3. **Gan loai phong:** theo quota + rang buoc (khong 2 elite lien ke; shop khong canh entrance; heal ngay truoc boss).
4. **Stamp template:** moi node lay 1 template (20x12 -> 40x24 tile) roi mutate dia hinh theo biome. Flood-fill check moi cua reachable.
5. **Dat quai:** budget diem, roll tu pool biome. Wave 2-3 giu 40% budget. Quai xa cach cua vao >= 6 tile.
6. **Dat bay:** 0-4 bay/phong, risk-reward placement, khong chan 100% cua duy nhat.
7. **Dat loot:** loot table theo rarity weight + pity system. Roll TRUOC va luu vao spawn_plan (deterministic).
8. **Chon boss:** pool 2-3 boss/biome, loai boss vua gap run truoc.
9. **Validate:** BFS tu entrance toi moi phong; fail -> re-roll CHI nhanh loi (giu seed on dinh).

## Rang buoc chong bat cong (bat buoc co automated test)
- Khong quai nao spawn trong ban kinh 3 tile quanh player khi mo cua.
- Luon ton tai >= 1 duong di khong dinh bay sat thuong.
- Unit test: gen 10.000 seed -> 0 map fail validate; do phan phoi loai phong.

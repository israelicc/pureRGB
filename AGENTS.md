# AGENTS.md — PureRGB source edit index

Purpose: fast lookup of **where to change what** in this fork. All paths relative to repo root (`pureRGB/`). This is a Game Boy Color ROM built from RGBDS assembly — no C, no runtime packages, no unit tests. Read this before editing source.

Full architecture notes live in `workspace-agents/index.md`. Behavior changelog: `FEATURES.md` (`Move changes` :464, `Pokemon type changes` :514, `Trainer AI changes` :537, `Visual changes` :353, `Bugfixes` :386).

---

## 0. Ground rules

1. **Constants are global.** `includes.asm:1-71` preloads all macros (`macros/`) and all `constants/*.asm` into every assembly unit via `Makefile:112` (`rgbasm -P includes.asm`). Name collisions are real.
2. **Mark fork edits** with `; PureRGBnote: ...`. 1,400+ existing markers; grep to find prior customizations: `grep -rn "PureRGBnote:" --include="*.asm" .`
3. **PNG is source.** Generated `*.1bpp`, `*.2bpp`, `*.pic`, `*.sgb.tilemap` are intermediates — never hand-edit; ignored by git (`.gitignore:1-16`).
4. **No `.pal` files exist.** Palettes are `RGB ...` directives in `data/gbc/*.asm`, `data/sgb/*.asm`, and `data/pokemon/*palettes.asm`.
5. **Banks are finite.** New code goes in `newCode` (`main.asm:402`), `newCode2` (`main.asm:451`), `newCode3` (`main.asm:473`), `movedCode`. Section→bank map: `layout.link`.
6. **Table length asserts are lockstep guards.** `assert_table_length` / `ASSERT` in `moves.asm:181`, `data/moves/names.asm:168`, `data/moves/animations.asm:170,217`, `data/moves/effects_pointers.asm:101`, `data/battle_anims/subanimations.asm:104`, `constants/*.asm` counts. Changing an ID constant requires updating every indexed table.
7. **Verification = build.** `make red|blue|green|all`. `make compare` checks SHA1 against upstream pret — it will fail for intentional fork changes. No test suite; emulator check needed for behavior. Details: `workspace-agents/overview/build-and-ci.md`.

---

## 1. Build / rebuild

| Task | Command / file | Notes |
|---|---|---|
| Full ROMs | `make red` / `make blue` / `make green` / `make all` | `Makefile:69-75` |
| One 2bpp | `make gfx/tilesets/overworld.2bpp` | rule `Makefile:208-211`; special flags `:178-203` |
| One 1bpp | `make gfx/font/font.1bpp` | rule `Makefile:213-216` |
| One sprite `.pic` | `make gfx/pokemon/front/abra.pic` | `Makefile:208-211` → `:218-219` (`pkmncompress`) |
| Clean generated gfx | `make clean` | `Makefile:77-83` |
| Tool bootstrap | `make -C tools` (automatic) | `tools/gfx.c`, `pkmncompress`, `scan_includes` — `Makefile:133-143` |
| Strict warnings | `rgbds` v1.0.4, `-Weverything -Wtruncation=1` | `Makefile:37-46`, `.rgbds-version` |
| Upstream parity | `make compare` | `Makefile:103-104`, `roms.sha1` |

`scan_includes` follows both `INCLUDE` and `INCBIN` (`tools/scan_includes.c:83-102`), so PNG edits trigger rebuilds.

---

## 2. Wiring map — where files are pulled in

| Manifest | Lines | What it wires |
|---|---|---|
| `includes.asm` | 1-71 | all macros + all constants, every unit |
| `home.asm` | 3-85 | ROM0 core: text engine, overworld text, print text, audio |
| `main.asm` | 1-483 | banked engine + data; see section names below |
| `text.asm` | 1-320 | 14 text banks, `data/pokemon/dex_text.asm`:312, `data/moves/names.asm`:316, `data/moves/movedex_text.asm`:320 |
| `maps.asm` | 1-~2500 | per-map header / scripts / objects / `.blk` |
| `audio.asm` | 1-487 | SFX banks 21-357, engines 358-379, music banks 382-477, new SFX 478-487 |
| `Makefile` | 1-19 | `gfx/pics.o`, `gfx/sprites.o`, `gfx/tilesets.o` as first-class objects |

Key `main.asm` sections: `Battle Engine 7` :161 (moves + cries), `Wild Mons` :332, `Evos Moves` :338, `newCode` :402, `newCode2` :451, `newCode3` :473. Bank placement: `layout.link`.

---

## 3. Pokémon — stats, evolution, moves learned, metadata

| Want to edit | File | Lines | Notes |
|---|---|---|---|
| Species base stats, types, catch rate, base exp, growth rate, level-1 moves, TM/HM learnset | `data/pokemon/base_stats/<species>.asm` | e.g. `bulbasaur.asm:1-14`, `tmhm` `:16-44` | Field order: dex id :1; HP/Atk/Def/Spd/Spc :3-4; types :6; catch :7; base exp :8; sprite dims/pointers :10-11; level-1 moves :13; growth :14; TM/HM bitfield :17+. PureRGB appends sprite-bank bytes :36-42. |
| Base stat struct layout | `constants/pokemon_data_constants.asm` | 1-30 (`BASE_DATA_SIZE` :30) | PureRGB alt-sprite fields :23-28 |
| Base-stat file index | `data/pokemon/base_stats.asm` | 1-169 | One `INCLUDE` per species; edit the individual file. Non-dex forms :156-169 |
| Growth-rate formulas | `data/growth_rates.asm` | 1-21 | Indexes `pokemon_data_constants.asm:91-100` |
| **Evolution + level-up learnsets** | `data/pokemon/evos_moves.asm` | format doc :1-13, pointers :15-207, data :209-2067 | `EVOLVE_LEVEL/ITEM/TRADE` constants `pokemon_data_constants.asm:84-86`. Empty/duplicated learnsets merged — check comments before adding |
| Learnset unlock scripting | `engine/overworld/learnset_scripts.asm` | — | flags `constants/event_constants.asm:1086`; family map `data/pokemon/pokemon_family_map.asm:1-155` |
| Move tutor (old TMs) | `data/pokemon/tutor_moves/tutor_moves.asm` + one file per move | 1-31; e.g. `mega_punch.asm:1-154` | offered moves `engine/events/tutor.asm:1-21` |
| Species IDs | `constants/pokemon_constants.asm` | 1-209 | `NUM_POKEMON_INDEXES` :201; PureRGB real MissingNo :190; `RESTLESS_SOUL` :209 |
| Dex IDs | `constants/pokedex_constants.asm` | 1-162 | `NUM_POKEMON` :162; MissingNo index 0 |
| Species names | `data/pokemon/names.asm` | 1-193 | Included at `engine/pokemon/get_mon_name.asm:16` |
| Dex flavor text | `data/pokemon/dex_text.asm` | 1-1509 | `text.asm:312` |
| Dex metadata (height/weight + pointer) | `data/pokemon/dex_entries.asm` | 1-189 | Fixed-size `dex_entry` :23-27 |
| Dex order | `data/pokemon/dex_order.asm` | 1-193 | `engine/menus/pokedex.asm:1186` |
| Dex categories | `constants/pokedex_category_constants.asm` 1-99; `data/pokemon/dex_pokemon_categories.asm` 1-279 | — | `pokedex.asm:1101` |
| Metric height/weight | `data/pokemon/metric_measurements.asm` | 1-170 | `main.asm:455` |
| Cries (SFX, pitch, length) | `data/pokemon/cries.asm` | 1-260 | PureRGB remaps :202-260; constants `music_constants.asm:83-121` |
| Title / credits mons | `data/pokemon/title_mons.asm` 1-55; `data/credits/credits_mons.asm` 1-55 | — | `engine/movie/title.asm:627`, `credits.asm:109` |
| TM/HM ID → move | `data/moves/tmhm_moves.asm` | 1-15 | TM/HM IDs `constants/item_constants.asm:95-199` |

**Absent in Gen 1 fork:** egg moves, gender ratio, egg groups, breeding. Don't look for them.

---

## 4. Moves & battle

### Move definition

| Want to edit | File | Lines | Notes |
|---|---|---|---|
| Move values: anim / effect / power / type / accuracy / PP | `data/moves/moves.asm` | macro :3-11, table :13-181 | Order = move ID. Renamed PureRGB moves noted inline (`:28` ROOST, `:36` FILTHY SLAM, `:51` HEAT RUSH, `:83` DRAIN PUNCH, `:147` SIPHON SNAG, `:149` FIREWALL, `:169` DUST CLAW) |
| Move IDs | `constants/move_constants.asm` | 1-174 | `NUM_ATTACKS` :174; animation IDs :176-234 |
| Move struct offsets | `constants/battle_constants.asm` | 30-38 | `MOVE_LENGTH` :38 |
| Effect IDs | `constants/move_effect_constants.asm` | 1-107 | new PureRGB effects :8,31-42,79-106 |
| Effect → handler pointer table | `data/moves/effects_pointers.asm` | 1-101 | must match effect constants order |
| Effect dispatcher | `engine/battle/effects.asm` | 1-24 | handler bodies :26-2027 |
| Move names | `data/moves/names.asm` | 1-168 pointers, 170-501 strings | 12-char limit in battle (:170); `text.asm:316` |
| Move SFX (ID, pitch, tempo) | `data/moves/sfx.asm` | 1-170 | `engine/battle/animations.asm:2783` |
| Movedex (PureRGB addition) | `data/moves/movedex_entries.asm` 1-170; `movedex_order.asm` 1-169; `movedex_text.asm` 1-1858; `movedex_type_palettes.asm` 1-100; engine `engine/menus/movedex.asm` 1-1033 | — | text :320; data load `movedex.asm:613-621`. `movedex_text2.asm` orphan — not INCLUDEd |
| TM/HM move list | `data/moves/tmhm_moves.asm` | 1-15 | `engine/items/tms.asm:37` |

### Effect classification tables (included from `engine/battle/core.asm:3-7`)

`data/battle/priority_moves.asm` 1-31 · `critical_hit_moves.asm` 1-7 · `always_happen_effects.asm` 1-18 · `special_effects.asm` 1-29 · `residual_effects_1.asm` 1-18 · `residual_effects_2.asm` 1-36 · `set_damage_effects.asm` 1-6 · `stat_modifiers.asm` 1-13 · `stat_mod_stat_mapping.asm` 1-78 · `mist_blocked_moves.asm` 1-8.

### Banked effect routines (one file per effect)

`engine/battle/move_effects/`: `burn.asm` (Firewall) · `conversion.asm` 1-565 · `defense_curl_effect.asm` · `drain_hp.asm` · `focus_energy.asm` · `haze.asm` · `heal.asm` · `leech_seed.asm` · `mist.asm` · `one_hit_ko.asm` · `paralyze.asm` · `pay_day.asm` · `recoil.asm` · `reflect_light_screen.asm` · `screech.asm` · `siphon_snag.asm` · `sleep.asm` · `substitute.asm` · `teleport.asm` · `transform.asm` · `tri_attack.asm` · `check_defrost_move.asm`. Wired from `main.asm:134-158,228-244,351-376,402-471`.

### Damage / accuracy / status / AI

| Want to edit | File | Lines |
|---|---|---|
| Turn loop, priority | `engine/battle/core.asm` | 309-428 |
| Player move pipeline | `engine/battle/core.asm` | 3336-3550 |
| Enemy move pipeline | `engine/battle/core.asm` | 5807-6026 |
| Damage variable setup | `engine/battle/core.asm` | 4262-4568 |
| Damage formula | `engine/battle/core.asm` | 4570-4733 |
| Critical hit test | `engine/battle/core.asm` | 4743-4811 |
| Apply damage / fixed damage | `engine/battle/core.asm` | 4817-5079 |
| STAB | `engine/battle/core.asm` 5238-5261; `moved_battle_code.asm` 83-151 | — |
| Type effectiveness | `engine/battle/core.asm` 5238-5389, 5472-5584; `data/types/type_matchups.asm` 1-110 | PureRGB rows :37,79,86-109 |
| Configurable type chart (option bits) | `engine/battle/core.asm` | 5391-5470 |
| Accuracy / hit test | `engine/battle/core.asm` | 5586-5767 |
| Damage randomization | `engine/battle/core.asm` | 5769-5804 |
| Status gating (sleep/freeze/etc.) | `engine/battle/core.asm` | 3606-3807 player, 6032-6252 enemy |
| Status tick (poison/burn/leech seed) | `engine/battle/core.asm` | 514-602, 712-761 |
| Burn/para penalties + badge boosts | `engine/battle/core.asm` | 6627-6880 |
| Status bit flags | `constants/battle_constants.asm` | 69-116 |
| **Signature moves / per-user power & accuracy** | `engine/battle/remap_move_data.asm` | 1-322; table :79-108, called `core.asm:3390` |
| Trainer AI move scoring | `engine/battle/trainer_ai.asm` | 3-1752; modifiers :145-1045 |
| PP tracking | `engine/battle/pp_tracker.asm` 1-225; `decrement_pp.asm` 1-41 | — |
| "Weather" substitute | `engine/battle/volcano_battle_init.asm` | 1-515 — **no Gen 1 weather system**; volcano/Tower field effects |
| Type constants | `constants/type_constants.asm` 1-32 | custom: `TYPELESS` 11, dynamic `GHOST` 13, `CRYSTAL` 14, `BONEMERANG` 15, `TRI` 21, `FLOATING` 22, `MAGMA` 23 |
| Type names | `data/types/names.asm` 1-51 | `print_type.asm:67` |

`engine/battle/used_move_text.asm` is orphaned (references missing `data/moves/grammar.asm`). Ignore.

---

## 5. Animations (move + overworld + intro)

| Want to edit | File | Lines | Notes |
|---|---|---|---|
| Animation IDs | `constants/move_constants.asm` | 176-234 | moves double as anim IDs |
| Per-move animation script pointers | `data/moves/animations.asm` | 3-217 | `AttackAnimationPointers` :3; 166 moves :5-169; non-move anims :171-216 |
| Animation script format | `data/moves/animations.asm` | 220-239 | `battle_anim` macro :228-237; sound ID, SE/subanim ID, tileset, delay; `db -1` terminator |
| Animation scripts | `data/moves/animations.asm` | 242-1572 | `PoundAnim` :246; PureRGB scripts :909,1337-1368,1468-1572 |
| SE / subanim / frameblock IDs | `constants/move_animation_constants.asm` | 1-504 | new SEs :6-20,29,32,41; new subanims :153-169 |
| SE id → routine | `data/battle_anims/special_effect_pointers.asm` | 1-60 | `engine/battle/animations.asm:1146` |
| Animation id → per-move SE | `data/battle_anims/special_effects.asm` | 1-40 | `engine/battle/animations.asm:759` |
| Subanimations | `data/battle_anims/subanimations.asm` | pointers 1-104, format 106-114, data 116-1066 | `subanim` macro :112-114 |
| Frame blocks | `data/battle_anims/frame_blocks.asm` | pointers 1-131, data 133-1240 | base coords `base_coords.asm`, incl. :1241 |
| Animation engine | `engine/battle/animations.asm` | draw :4-192, play :194-304, load subanim :306-388, tile load :390-432 | `main.asm:327` |
| Animation tile graphics | `gfx/battle/move_anim_0.png`, `move_anim_1.png`, `move_anim_2.png` | — | `engine/battle/animations.asm:431-432`, `engine/battle/animations/move_animation_tiles.asm:1-5` |
| Extra PureRGB anim codes | `engine/battle/animations/tri_attack.asm` 1-37; `custom_send_out_mon_ball_poof_animations.asm` 1-2476 | — | `main.asm:428`, `:459` |
| Animation palettes (OBP) | `engine/gfx/set_attack_animation_palette.asm` 1-240+ | — | mapping :166-201; applied `animations.asm:279-293` |
| Overworld sprite frames | `data/sprites/facings.asm` 1-59; `engine/gfx/sprite_oam.asm` 69-153 | — | 32 standing/walking entries |
| Party icon animation | `engine/gfx/mon_icons.asm` 34-117 | speeds :114-117 | — |
| Intro frames | `engine/movie/intro.asm` 365-436 | `IntroNidorinoAnimation0..7` | — |
| Title frames | `engine/movie/title.asm` 659-1021, 1280-1429 | PureRGB blinking/shine :1314-1429 | — |

---

## 6. Graphics & palettes

| Want to edit | File | Notes |
|---|---|---|
| Front battle sprites | `gfx/pokemon/front/*.png` | → `.pic`; pointers `gfx/pics.asm:14-60` etc. |
| Back sprites | `gfx/pokemon/back/*.png` (OG), `back_sw/*.png` (SW97) | `gfx/pics.asm:216-219,320-324,436-566` |
| Alt ("shiny") front sprites | `gfx/pokemon/front_alt/*.png` (38) | toggle `engine/gfx/front_sprite_toggler.asm:1-83` |
| Sprite pointer/dimension/bank bytes | `data/pokemon/base_stats/<species>.asm:10-11,36-42` | bank select `home/pics.asm:5-18` |
| Overworld NPC sprites | `gfx/sprites/*.png` (108) → `gfx/sprites.asm:1-146`; pointers `data/sprites/sprites.asm:3-132`; constants `constants/sprite_constants.asm` | remap `data/sprites/alt_sprite_mappings.asm:1-22` |
| Trainer sprites | `gfx/trainers/*.png` (46) → `gfx/pics.asm:274-318`; table `data/trainers/pic_pointers_money.asm:1-66` | — |
| Party menu icons | `gfx/icons/menusprites1.png`, `menusprites2.png` → `main.asm:378-381` | mapping `data/pokemon/menu_icons_new.asm`, `menu_icons.asm`; engine `mon_icons2.asm:92-109,191-225` |
| Item/ball/badge gfx | `gfx/sprites/poke_ball.png`, `gfx/battle/balls.png`, `gfx/battle/ball_anim.png`, `gfx/trainer_card/badges.png` | no `gfx/items/` dir |
| Tilesets + collision | `gfx/tilesets/*.png` → `gfx/tilesets.asm:1-78`; `gfx/blocksets/*.bst` | special trim rule `Makefile:196-197` |
| Animated tiles | `gfx/tilesets/flower/`, `lava/`, `electricity/` | code `engine/gfx/animated_tiles_code.asm:14-76,384-393` |
| Title / intro / credits / font | `gfx/title/`, `gfx/intro/`, `gfx/splash/`, `gfx/credits/`, `gfx/font/` | `engine/movie/title.asm:15-120`, `intro.asm:438-467`, `gfx/font.asm:1-30` |
| Per-species palettes | `data/pokemon/palettes.asm` 1-190+, `alt_palettes.asm` 1-190+ | dispatch `engine/gfx/palettes.asm:1-267,488-507` |
| GBC palettes | `data/gbc/gbc_palettes.asm` 1-122, `gbc_palettes2.asm` 1-95 | BG attrs `data/gbc/bg_map_attributes.asm` 4-481+ |
| SGB palettes / borders | `data/sgb/sgb_palettes.asm` 1-80, `sgb_palettes2.asm` 1-83, `sgb_border.asm` 1-88, `sgb_packets.asm` 56-354 | — |
| Palette IDs | `constants/palette_constants.asm` 1-77 | macros `macros/gfx.asm:1-24` |
| Movedex type icon palettes | `data/moves/movedex_type_palettes.asm` 1-80 | — |

Reference-only PNG folders (not INCBIN'd): `gfx/pokemon/front_rb`, `front_rg`, `back_original`, `back_sw_original`, `gallery`, `gfx/tilesets/tilesets_rg`, `gfx/camera/base colors`.

---

## 7. Items / trainers / wild / events

| Want to edit | File | Notes |
|---|---|---|
| Item IDs | `constants/item_constants.asm` 1-93, 95-202 | TMs :130-192, HMs :104-126, PureRGB additions :14,30,32-34,53,59,78,84,140 |
| Item names | `data/items/names.asm` 1-255 | `main.asm:9` |
| Prices | `data/items/prices.asm` 1-87, `tm_prices.asm` 1-56 | `get_prices.asm:30,56` |
| Item use dispatch + handlers | `engine/items/item_effects.asm` 1-3500+ | table :22-106, handlers :108+ |
| Key items / usable lists | `data/items/key_items.asm`, `use_party.asm`, `use_overworld.asm`, `guard_drink_items.asm`, `vending_prices.asm` | — |
| Mart inventories | `data/items/marts/*.asm` (13) | referenced from `scripts/<Mart>.asm` |
| Trainer class IDs | `constants/trainer_constants.asm` 1-76 | new PureRGB classes :62-74 |
| Trainer names | `data/trainers/names.asm` 1-59 | — |
| Trainer parties (species + levels) | `data/trainers/parties.asm` 1-906 | `trainer_ai.asm:1068`. `parties_original.asm` is reference only |
| Custom trainer movesets | `data/trainers/custom_movesets.asm` 1-699 | `main.asm:439` |
| Trainer AI data | `ai_pointers.asm` 1-63, `move_choices.asm` 1-75, `special_moves.asm` 1-24, `encounter_types.asm` 1-34 | loads `read_trainer_party.asm:90,138` |
| Wild grass/water | `data/wild/grass_water.asm` 1-332 + `data/wild/maps/*.asm` (66) | format comment :256-265; 10 grass + 10 water slots per map |
| Encounter slot odds | `data/wild/probabilities.asm` 1-28 | `wild_encounters.asm:215` |
| Fishing | `data/wild/good_rod.asm` 1-41, `super_rod.asm` 1-206 | `item_effects.asm:2269,3529` |
| Wild alt palettes | `data/wild/palettes/wild_palettes.asm` 1-330 + `maps/*.asm` | `main.asm:336` |
| In-game trades / prizes | `data/events/trades.asm` 1-37, `prizes.asm` 1-45, `prize_mon_levels.asm` 1-10 | — |
| Hidden items | `data/events/hidden_item_coords.asm` 1-80 | `hidden_items.asm:52` |

---

## 8. Text, names, UI, options

| Want to edit | File | Notes |
|---|---|---|
| Map NPC/sign dialogue | `text/<Map>.asm` (one per map) | wire ID in `scripts/<Map>.asm` (`*_TextPointers`, e.g. `PalletTown.asm:142-150`) + `data/maps/objects/<Map>.asm:18-27`; ensure INCLUDE in `text.asm:5-309` |
| Generic/system strings | `data/text/text_1.asm` … `text_7.asm` | text_1 :1-260; text_2 :1-1911; text_3 :1-419; text_4 :1-231; text_5 :1-206; text_6 :1-336; text_7 :1-213 |
| Text macros | `macros/scripts/text.asm` 1-280 | `text/next/line/para/cont/done`, `text_far`, `TX_*`, generic script IDs :234-280 |
| Charmap shortcuts | `constants/charmap.asm` 1-52 | PureRGB shortcuts :14-28 |
| Text IDs | `constants/text_constants.asm` 1-31; `macros/const.asm:47-55` (`dba_const`) | dispatcher `home/text_script.asm:1-94` |
| Text engine | `home/text.asm` 49-849; `home/print_text.asm` 1-44 | commands :394-849, sound map :683-689 |
| Species / move / item / trainer names | `data/pokemon/names.asm`, `data/moves/names.asm`, `data/items/names.asm`, `data/trainers/names.asm` | — |
| Option label | `engine/menus/options_menu.asm`, `options_menu2.asm`, `battle_options.asm`, `options_menu3.asm`, `sprite_options_menu.asm`, `front_sprite_options*.asm`, `world_options.asm` | labels e.g. `options_menu.asm:421-431` |
| Option help text (SELECT:INFO) | `text/OptionsInfoText.asm` 1-244 | — |
| Option bits / flags | `constants/ram_constants.asm` 171-254 | `wOptions2` :175-189, `wOptions3` :191-200, sprite opts :202-244 |
| Object visibility toggles | `constants/toggle_constants.asm` 1-564; `data/maps/toggleable_objects.asm`; engine `toggleable_objects.asm:21,59,97` | original set `original_toggle_constants.asm` 1-392 |
| Text boxes / menus | `data/text_boxes.asm` 1-93, `data/yes_no_menu_strings.asm` 1-46, `engine/menus/text_box.asm`, `home/list_menu.asm`, `engine/menus/start_sub_menus.asm` | IDs `constants/menu_constants.asm:4-32` |
| Main/start menu strings | `engine/menus/main_menu.asm:400-427`, `draw_start_menu.asm:1-88` | — |

---

## 9. Audio

| Want to edit | File | Notes |
|---|---|---|
| Music/SFX IDs | `constants/music_constants.asm` 1-254 | music :8-57, cries :83-122, battle SFX :179-232, new :249-254 |
| Song headers | `audio/headers/musicheaders1.asm`, `2`, `3` | — |
| SFX headers | `audio/headers/sfxheaders1.asm`, `2`, `3` | header order defines IDs via `music_const` |
| Music note data | `audio/music/*.asm`; engine `audio/engine_1.asm`, `engine_2.asm`, `engine_3.asm`, `notes.asm`, `drumkits.asm`, `wave_samples.asm` | — |
| SFX data | `audio/sfx/*.asm` | PureRGB examples `fall_down_hole.asm`, `volcano_sfx.asm`, `static_encounter_sfx.asm`, `extra_battle_sfx.asm` |
| Per-map song | `data/maps/songs.asm` 1-400+ | `MapSongBanks` |
| Audio manifest | `audio.asm` 1-487 | new SFX bank :478-487 |
| Text sound commands | `home/text.asm:648-689` | `TextCommandSounds` :683-689 |
| Audio macros | `macros/scripts/audio.asm` | `includes.asm:11` |

---

## 10. Maps / scripts

| Want to edit | File | Notes |
|---|---|---|
| Map header + connections | `data/maps/headers/<Map>.asm`; macros `macros/scripts/maps.asm:138-250` | — |
| Warps / signs / object events | `data/maps/objects/<Map>.asm`; macros `macros/scripts/maps.asm:1-93` | `object_event` text ID :12,30,36; `warp_event` :51-56; `bg_event` :58-71 |
| Map script + text pointer table | `scripts/<Map>.asm` | example `PalletTown.asm:1-189`, pointers :142-150 |
| Tile data | `maps/<Map>.blk` (binary) | — |
| Sprite set per map | `data/maps/sprite_sets.asm` 1-40+ | — |
| Floor names | `engine/events/get_floor_name.asm:15-32` | — |
| Warp text | `data/text/text_5.asm:49-56` | — |
| Manifest | `maps.asm` 1-~2500 | pattern header → scripts → objects → `.blk` |

---

## 11. Common change recipes

- **Tweak a species stat/type/catch rate**: edit `data/pokemon/base_stats/<species>.asm`; rebuild. If TM learnset, also check `data/moves/tmhm_moves.asm`.
- **Change evolution or level-up move**: edit `data/pokemon/evos_moves.asm` block for that species (check pointer table :15-207 and "shared learnset" comments).
- **Change move power/type/accuracy/PP/effect**: edit row in `data/moves/moves.asm`; if effect, add handler in `engine/battle/effects.asm` or `engine/battle/move_effects/`, wire `constants/move_effect_constants.asm` + `data/moves/effects_pointers.asm`; update `data/moves/names.asm` and `data/moves/movedex_text.asm`.
- **Add a move**: sync `constants/move_constants.asm`, `moves.asm`, `names.asm`, `animations.asm` pointers, `sfx.asm`, `movedex_entries.asm` + `movedex_order.asm` + `movedex_text.asm`, `effects_pointers.asm`, `tmhm_moves.asm` if TM. Watch all `assert_table_length`.
- **Change move animation**: edit script in `data/moves/animations.asm`; new SE/subanim needs `constants/move_animation_constants.asm` + `data/battle_anims/special_effect_pointers.asm` / `subanimations.asm` + `frame_blocks.asm` + routine in `engine/battle/animations.asm`.
- **Change type chart**: `data/types/type_matchups.asm`; option-dependent rows handled in `engine/battle/core.asm:5391-5470`.
- **Swap a sprite**: replace PNG in `gfx/pokemon/front|back|back_sw|front_alt/`; keep size/palette constraints; `make clean && make <variant>`; alt-front must be registered in `data/pokemon/base_stats/<species>.asm` and toggle mapping.
- **Change NPC dialogue**: `text/<Map>.asm`; update `scripts/<Map>.asm` pointer table and `data/maps/objects/<Map>.asm` text IDs if adding a new ID.
- **Add an item**: `constants/item_constants.asm` → `data/items/names.asm`, `prices.asm`, `item_effects.asm:22-106` + handler, `use_party/use_overworld`, mart list. `NUM_ITEMS` assert.
- **Add an option**: `constants/ram_constants.asm:171-254` bit → label in `engine/menus/options_menu*.asm` → help in `text/OptionsInfoText.asm` → engine check.
- **Change trainer roster**: `data/trainers/parties.asm`; AI/moveset in `data/trainers/custom_movesets.asm`, `move_choices.asm`, `special_moves.asm`.
- **Change wild encounters**: `data/wild/maps/<Map>.asm` (or add to `grass_water.asm:267-332` pointer list).

---

## 12. Gotchas

- `assert_table_length` failures mean an ID constant and its table are out of sync. Fix both.
- Adding code to a full bank: move to `newCode*` sections (`main.asm:402-479`), update `layout.link` if new section.
- `make compare` will report differences — fork intentionally deviates from upstream. Verify with clean build + emulator.
- Orphan/not-INCLUDEd files: `data/moves/movedex_text2.asm`, `data/trainers/parties_original.asm`, `engine/battle/used_move_text.asm`, `data/moves/hm_moves.asm` (includes commented out), `gfx/pokemon/*_original` / `tilesets_rg` reference PNGs. Edit only if you also wire them in.
- No `gfx` make target: use suffix rules (`make gfx/pokemon/front/abra.pic`).
- Some base-stat files have multiple sprite pointer sets (SW97/alt/shiny) — changing only the front PNG may not change what the game displays under options.

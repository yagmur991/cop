extends Node
# Localization (English / Türkçe) + saved settings. Autoload: "Loc".
# Use Loc.t("key") or Loc.t("key", [args]). Index 0 = English, 1 = Turkish.

signal language_changed
signal volume_changed

const SETTINGS_PATH := "user://settings.cfg"

var lang := "en"
var fullscreen := false
var music_vol := 0.6
var sfx_vol := 0.8

var S := {
    # ---------------- general / names ----------------
    "game_title": ["SAVE GAIA", "SAVE GAIA"],
    "tagline": ["Collect. Recycle. Save the world.", "Topla. Geri dönüştür. Dünyayı kurtar."],
    "trash_glass": ["Glass", "Cam"],
    "trash_metal": ["Metal", "Metal"],
    "trash_paper": ["Paper", "Kağıt"],
    "trash_plastic": ["Plastic", "Plastik"],
    "done": ["DONE", "TAMAM"],
    # ---------------- main / pause menu ----------------
    "m_new": ["New Game", "Yeni Oyun"],
    "m_continue": ["Continue", "Devam Et"],
    "m_howto": ["How to Play", "Nasıl Oynanır"],
    "m_options": ["Options", "Seçenekler"],
    "m_credits": ["Credits", "Emeği Geçenler"],
    "m_quit": ["Quit", "Çıkış"],
    "m_nosave": ["No save found", "Kayıt bulunamadı"],
    "p_title": ["PAUSED", "DURAKLATILDI"],
    "p_resume": ["Resume", "Devam"],
    "p_menu": ["Quit to Menu", "Ana Menüye Dön"],
    "p_note": ["Progress is saved at every level start and boss fight.", "İlerleme her bölüm başında ve boss savaşında kaydedilir."],
    # ---------------- difficulty ----------------
    "d_title": ["Choose Difficulty", "Zorluk Seç"],
    "d_easy": ["Easy", "Kolay"],
    "d_normal": ["Normal", "Normal"],
    "d_hard": ["Hard", "Zor"],
    "d_easy_desc": ["More health, slower pollution, gentler enemies and bosses.", "Daha fazla can, yavaş kirlilik, daha yumuşak düşmanlar ve bosslar."],
    "d_normal_desc": ["The intended experience.", "Tasarlandığı gibi deneyim."],
    "d_hard_desc": ["Less health, fast pollution, tougher enemies and bosses.", "Az can, hızlı kirlilik, daha sert düşmanlar ve bosslar."],
    # ---------------- options / credits ----------------
    "o_title": ["Options", "Seçenekler"],
    "o_language": ["Language", "Dil"],
    "o_fullscreen": ["Fullscreen", "Tam Ekran"],
    "o_on": ["On", "Açık"],
    "o_off": ["Off", "Kapalı"],
    "o_music": ["Music Volume", "Müzik Sesi"],
    "o_sfx": ["Sound Volume", "Ses Efektleri"],
    "o_back": ["Back", "Geri"],
    "c_title": ["Credits", "Emeği Geçenler"],
    "c_1": ["A game made for the hackathon by the Save Gaia team", "Save Gaia ekibi tarafından hackathon için yapıldı"],
    "c_2": ["Recycling bin sprite: yureino-kage (itch.io)", "Geri dönüşüm kutusu sprite'ı: yureino-kage (itch.io)"],
    "c_3": ["Made with Godot Engine", "Godot Engine ile yapıldı"],
    "c_4": ["Music and sounds: original chiptune pieces made for this game", "Müzik ve sesler: bu oyun için yapılmış özgün chiptune besteler"],
    "c_5": ["Thanks for playing!", "Oynadığın için teşekkürler!"],
    "nav_hint": ["W/S or Up/Down: select    Enter: confirm    Esc: back", "W/S veya Yukarı/Aşağı: seç    Enter: onayla    Esc: geri"],
    "nav_hint_lr": ["A/D or Left/Right: choose    Enter: confirm    Esc: back", "A/D veya Sol/Sağ: seç    Enter: onayla    Esc: geri"],
    # ---------------- how to play ----------------
    "h_title": ["How to Play", "Nasıl Oynanır"],
    "h_page": ["Page %d/%d", "Sayfa %d/%d"],
    "h_p1": ["Controls", "Kontroller"],
    "h_p2": ["Your Mission", "Görevin"],
    "h_p3": ["Items & Bins", "Itemler ve Kutular"],
    "h_p4": ["Bosses & Tips", "Bosslar ve İpuçları"],
    "h_move": ["Move (A / D or arrow keys)", "Hareket (A / D veya yön tuşları)"],
    "h_jump": ["Jump (double jump after an upgrade)", "Zıpla (upgrade ile çift zıplama)"],
    "h_attack": ["Attack - also opens chests", "Saldır - sandıkları da açar"],
    "h_inv": ["Inventory", "Envanter"],
    "h_pause": ["Pause menu", "Duraklatma menüsü"],
    "h_m1": ["Defeat the trash monsters and smash open chests: they drop items.", "Çöp canavarlarını yen ve sandıkları kır: item düşürürler."],
    "h_m2": ["Saplings clean the air: each one lowers pollution and gives a clean upgrade. Grow a chest's saplings into a tree!", "Fidanlar havayı temizler: her biri kirliliği düşürür ve temiz bir upgrade verir. Bir sandığın fidanlarını ağaca dönüştür!"],
    "h_m3": ["Trash makes you stronger but raises pollution. You carry glass, metal, paper and plastic: pick one with Q or 1-4.", "Çöp seni güçlendirir ama kirliliği artırır. Cam, metal, kağıt ve plastiği taşırsın: Q veya 1-4 ile birini seç."],
    "h_m4": ["Pollution also rises over time. At high levels, heat waves hurt you!", "Kirlilik zamanla da artar. Yüksek seviyede sıcak hava dalgaları canını yakar!"],
    "h_m5": ["Stand in the matching bin and press E to drop the selected trash. A wrong bin adds pollution! Fill all bins but one to open the boss gate - all of them gives a bonus.", "Eşleşen kutunun içinde dur ve seçili çöpü atmak için E'ye bas. Yanlış kutu kirliliği artırır! Boss kapısı için bir kutu hariç hepsini doldur - hepsini doldurursan bonus kazanırsın."],
    "h_m6": ["Defeat the boss to move on. The game saves before and after every boss.", "İlerlemek için boss'u yen. Oyun her boss'tan önce ve sonra kayıt alır."],
    "h_i_sapling": ["Sapling: a clean upgrade and less pollution", "Fidan: temiz upgrade ve daha az kirlilik"],
    "h_i_trash": ["Trash: +1 damage, but more pollution", "Çöp: +1 hasar, ama daha fazla kirlilik"],
    "h_i_bin": ["Recycling bins: stand inside and press E", "Geri dönüşüm kutuları: içinde dur ve E'ye bas"],
    "h_i_gate": ["Boss gate: opens when all bins but one are full", "Boss kapısı: bir kutu hariç hepsi dolunca açılır"],
    "h_i_up": ["Upgrades: speed, shield, double jump, extra health", "Upgrade'ler: hız, kalkan, çift zıplama, ekstra can"],
    "h_t1": ["A red ! means the boss is about to attack. Get ready!", "Kırmızı ! boss'un saldıracağı anlamına gelir. Hazırlan!"],
    "h_t2": ["Jump over ground waves and keep moving.", "Yer dalgalarının üstünden zıpla ve hareket etmeye devam et."],
    "h_t3": ["Below half health the boss gets angry and faster.", "Canı yarıya inince boss öfkelenir ve hızlanır."],
    "h_t4": ["Keep pollution under 50 for the good ending.", "İyi son için kirliliği 50'nin altında tut."],
    "h_t5": ["Each character has a small perk. Pick the one that fits your style.", "Her karakterin küçük bir perk'ü var. Tarzına uyanı seç."],
    "h_next": ["Next", "İleri"],
    "h_start": ["Start!", "Başla!"],
    "h_close": ["Close", "Kapat"],
    "h_hint": ["A/D: pages    Enter: next    Esc: close", "A/D: sayfalar    Enter: ileri    Esc: kapat"],
    "h_hint_tut": ["A/D: pages    Enter: next    Esc: skip", "A/D: sayfalar    Enter: ileri    Esc: atla"],
    # ---------------- HUD / messages ----------------
    "hud_hp": ["HP %d/%d    Temp: +%.1f°C", "CAN %d/%d    Sıcaklık: +%.1f°C"],
    "hud_pollution": ["Pollution", "Kirlilik"],
    "hud_hint": ["E: Deposit   Q / 1-4: Select trash   B: Inventory   J/X: Attack   Space/W: Jump   Esc: Pause", "E: At   Q / 1-4: Çöp seç   B: Envanter   J/X: Saldır   Boşluk/W: Zıpla   Esc: Duraklat"],
    "inv_title": ["INVENTORY  (B to close)", "ENVANTER  (kapatmak için B)"],
    "inv_carry": ["Carrying: Glass %d | Metal %d | Paper %d | Plastic %d", "Taşınan: Cam %d | Metal %d | Kağıt %d | Plastik %d"],
    "inv_shield": ["Shield: %d", "Kalkan: %d"],
    "inv_speed": ["Speed: +%d", "Hız: +%d"],
    "inv_damage": ["Damage: +%d", "Hasar: +%d"],
    "inv_double": ["Double jump: %s", "Çift zıplama: %s"],
    "inv_yes": ["YES", "VAR"],
    "inv_no": ["no", "yok"],
    "inv_saplings": ["Saplings planted: %d", "Dikilen fidan: %d"],
    "inv_trash_total": ["Trash collected: %d", "Toplanan çöp: %d"],
    "inv_pollution": ["Pollution: %d%%", "Kirlilik: %%%d"],
    "inv_lock": ["Gate lock: %d/%d bins", "Kapı kilidi: %d/%d kutu"],
    "inv_arena": ["Boss arena", "Boss arenası"],
    "msg_intro": ["Collect trash, pick the RIGHT bin and press E, open the gate!", "Çöpleri topla, DOĞRU kutuyu seç ve E'ye bas, kapıyı aç!"],
    "msg_saved": ["Game saved", "Oyun kaydedildi"],
    "msg_gate_locked": ["The gate is locked! Fill the recycling bins (%d/%d needed)", "Kapı kilitli! Geri dönüşüm kutularını doldur (%d/%d gerekli)"],
    "msg_gate_open": ["LOCK OPEN! The gate awaits. Fill the last bin too for a greener world!", "KİLİT AÇILDI! Kapı seni bekliyor. Son kutuyu da doldur, dünya daha yeşil olsun!"],
    "msg_bin": ["%s bin: %d/%d (pollution down)", "%s kutusu: %d/%d (kirlilik düştü)"],
    "msg_died": ["You were defeated! Restarting...", "Yenildin! Yeniden başlıyor..."],
    "msg_boss_down": ["BOSS DEFEATED!", "BOSS YENİLDİ!"],
    "msg_enraged": ["THE BOSS IS ENRAGED! It attacks faster!", "BOSS ÖFKELENDİ! Daha hızlı saldırıyor!"],
    "msg_heat": ["HEAT WAVE! Lower the pollution!", "SICAK HAVA DALGASI! Kirliliği düşür!"],
    "msg_shield": ["The shield absorbed the hit!", "Kalkan hasarı emdi!"],
    "msg_trash": ["%s trash! Damage +1, but pollution rose. Find the right bin and press E!", "%s atığı! Hasar +1 ama kirlilik arttı. Doğru kutuyu bul ve E'ye bas!"],
    "msg_up_dj": ["Sapling planted: Double jump!", "Fidan dikildi: Çift zıplama!"],
    "msg_up_speed": ["Sapling planted: Speed up!", "Fidan dikildi: Hız artışı!"],
    "msg_up_shield": ["Sapling planted: Shield (absorbs 1 hit)!", "Fidan dikildi: Kalkan (1 hasarı emer)!"],
    "msg_up_heal": ["Sapling planted: +1 health!", "Fidan dikildi: +1 can!"],
    "lv_num": ["LEVEL %d", "BÖLÜM %d"],
    "lv_sea": ["Save the Sea", "Denizi Kurtar"],
    "lv_air": ["Save the Air", "Havayı Kurtar"],
    "lv_land": ["Save the Land", "Toprağı Kurtar"],
    "lv_sea_sub": ["Plastic is choking our oceans.", "Plastik okyanusları boğuyor."],
    "lv_air_sub": ["Factory smoke and carbon are poisoning the sky.", "Fabrika dumanı ve karbon gökyüzünü zehirliyor."],
    "lv_land_sub": ["Waste is burying the land. Stop the Landfill Titan!", "Atıklar toprağı gömüyor. Çöp Devi'ni durdur!"],
    "lv_continue": ["Press Enter to start", "Başlamak için Enter'a bas"],
    "msg_wrong": ["Wrong bin! %s doesn't belong in the %s bin. Pollution rose!", "Yanlış kutu! %s atığı %s kutusuna girmez. Kirlilik arttı!"],
    "msg_nohold": ["You aren't holding that. Choose with Q or 1-4.", "Elinde bu yok. Q veya 1-4 ile seç."],
    "msg_perfect": ["PERFECT SORTING! Extra greenery: pollution -12", "MÜKEMMEL AYIRMA! Ekstra yeşillik: kirlilik -12"],
    "sum_bins": ["Bins filled", "Dolan kutu"],
    "carry_hint": ["E: put in bin  |  Q / 1-4: choose", "E: kutuya at  |  Q / 1-4: seç"],
    "h_deposit": ["Put the selected trash in a bin", "Seçili çöpü kutuya at"],
    "h_select": ["Choose which trash to drop", "Hangi çöpü atacağını seç"],
    "fact_title": ["Did you know?", "Biliyor muydun?"],
    "fact_boss_sea": ["The best waste is the waste never created: reduce first, then reuse, and recycle last.", "En iyi atık hiç oluşmayan atıktır: önce azalt, sonra yeniden kullan, en son geri dönüştür."],
    "fact_boss_air": ["Wind and solar power make electricity without burning any fuel.", "Rüzgâr ve güneş enerjisi, yakıt yakmadan elektrik üretir."],
    "fact_boss_land": ["The UN's International Day of Zero Waste (30 March) was proposed by Türkiye.", "BM'nin Uluslararası Sıfır Atık Günü (30 Mart), Türkiye'nin önerisiyle ilan edildi."],
    "boss_label": ["BOSS", "BOSS"],
    "boss_plastic": ["Plastic Behemoth", "Plastik Canavar"],
    "boss_factory": ["Carbon Crusher", "Karbon Ezici"],
    "boss_land": ["Landfill Titan", "Çöp Devi"],
    "sum_title": ["Level Complete!", "Bölüm Tamamlandı!"],
    "sum_sea": ["The sea can breathe again!", "Deniz yeniden nefes alıyor!"],
    "sum_air": ["The sky is clearing up!", "Gökyüzü açılıyor!"],
    "sum_land": ["The land can heal!", "Toprak iyileşebilir!"],
    "sum_star_acc": ["Sorting accuracy 80%+", "Ayırma doğruluğu %80+"],
    "sum_star_poll": ["Pollution under 50%", "Kirlilik %50'nin altında"],
    "sum_star_death": ["No deaths", "Hiç ölmeden"],
    "sum_ok": ["Sorted correctly", "Doğru ayrılan"],
    "sum_wrong": ["Wrong bin", "Yanlış kutu"],
    "sum_acc": ["Sorting accuracy", "Ayırma doğruluğu"],
    "sum_kills": ["Monsters defeated", "Yenilen canavar"],
    "sum_trash": ["Trash collected", "Toplanan çöp"],
    "sum_saplings": ["Saplings planted", "Dikilen fidan"],
    "sum_poll": ["Pollution", "Kirlilik"],
    "sum_deaths": ["Deaths", "Ölüm"],
    "sum_upg": ["Upgrades", "Geliştirmeler"],
    "sum_none": ["none", "yok"],
    "sum_continue": ["Press Enter to continue", "Devam etmek için Enter'a bas"],
    "sum_continue_last": ["Press Enter to see the ending", "Sonu görmek için Enter'a bas"],
    "up_damage": ["damage", "hasar"],
    "up_speed": ["speed", "hız"],
    "up_shield": ["shield", "kalkan"],
    "up_double": ["double jump", "çift zıplama"],
    "msg_fury": ["THE LANDFILL TITAN IS DESPERATE! Everything at once!", "ÇÖP DEVİ ÇILGINA DÖNDÜ! Her şey bir arada!"],
    # ---------------- characters ----------------
    "char_0_name": ["Green", "Yeşil"],
    "char_1_name": ["Blue", "Mavi"],
    "char_2_name": ["Yellow", "Sarı"],
    "char_3_name": ["Purple", "Mor"],
    "char_4_name": ["Pink", "Pembe"],
    "char_0_perk": ["Nature Friend: starts with +1 health", "Doğa Dostu: +1 canla başlar"],
    "char_1_perk": ["Windrunner: runs a little faster", "Rüzgâr: biraz daha hızlı koşar"],
    "char_2_perk": ["Spark: faster attacks", "Işık: saldırı daha seri"],
    "char_3_perk": ["Calm: pollution rises more slowly", "Sakin: kirlilik daha yavaş artar"],
    "char_4_perk": ["Guardian: starts with a shield", "Koruyucu: kalkanla başlar"],
    "cs_title": ["WHO ARE YOU?", "KİMSİN SEN?"],
    "cs_sub": ["Choose your character", "Karakterini seç"],
    "cs_hint": ["A/D or Left/Right: choose    Enter: confirm", "A/D veya Sol/Sağ: seç    Enter: onayla"],
    # ---------------- cutscenes ----------------
    "cs_skip": ["Esc: skip", "Esc: atla"],
    "cs_next": ["Enter >", "Enter >"],
    "who_narrator": ["NARRATOR", "ANLATICI"],
    "who_gaia": ["PROF. GAIA", "PROF. GAIA"],
    "intro_1": ["Once upon a time, our world was blue and green. Everything was in its place.", "Bir zamanlar dünyamız mavi ve yemyeşildi. Her şey yerli yerindeydi."],
    "intro_2": ["But the factories never stopped and the trash kept piling up. Climate change and global warming began to scorch the planet.", "Ama fabrikalar durmadı, çöpler büyüdü. İklim değişikliği ve küresel ısınma dünyayı kasıp kavurmaya başladı."],
    "intro_3": ["Cities fell into ruin, summers burn, and the air is poisonous...", "Şehirler harap oldu, yazlar yakıcı, hava zehirli..."],
    "intro_4": ["The oceans are filling with plastic and the glaciers are melting. Time is running out.", "Okyanuslar plastikle doldu, buzullar eriyor. Zaman hızla tükeniyor."],
    "intro_5": ["There is still hope! If we sort our waste and recycle it properly, we can save the world. We chose you for this mission!", "Hâlâ umut var! Atıkları doğru ayırıp geri dönüştürürsek dünyayı kurtarabiliriz. Bu görev için seni seçtik!"],
    "good_1": ["You did it! The air is clean, the rivers are clear, and the wind turbines spin again.", "Başardın! Hava temizlendi, nehirler berraklaştı, rüzgâr türbinleri yeniden dönüyor."],
    "good_2": ["Congratulations! We were right to choose you. The world can breathe again. You are a hero!", "Tebrikler! Seni seçmekte haklıymışız. Dünya yeniden nefes alıyor. Sen bir kahramansın!"],
    "bad_1": ["We were too late... Pollution covers everything. The world is worse than ever.", "Çok geç kaldık... Kirlilik her yeri sardı. Dünya eskisinden de kötü durumda."],
    "bad_2": ["Professor Gaia, who gave us this mission, could not bear to see this disaster. They are no longer with us...", "Bize bu görevi veren Prof. Gaia bu felaketi görmeye dayanamadı. Artık aramızda değil..."],
    "end_clean": ["CLEAN ENDING", "TEMİZ SON"],
    "end_dirty": ["DIRTY ENDING", "KİRLİ SON"],
    "end_stats": ["%s\n\nTrash collected: %d\nRecycled: %d\nPollution: %d%%\n\nPress Enter to return to the menu", "%s\n\nToplanan atık: %d\nGeri dönüştürülen: %d\nKirlilik: %%%d\n\nMenüye dönmek için Enter'a bas"],
}


func _ready() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SETTINGS_PATH) == OK:
        lang = str(cfg.get_value("game", "lang", "en"))
        fullscreen = bool(cfg.get_value("game", "fullscreen", false))
        music_vol = float(cfg.get_value("game", "music_vol", 0.6))
        sfx_vol = float(cfg.get_value("game", "sfx_vol", 0.8))
    # deferred: the window must exist before its mode can be changed reliably
    _apply_fullscreen.call_deferred(false)


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
        set_fullscreen(not fullscreen)


func _save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("game", "lang", lang)
    cfg.set_value("game", "fullscreen", fullscreen)
    cfg.set_value("game", "music_vol", music_vol)
    cfg.set_value("game", "sfx_vol", sfx_vol)
    cfg.save(SETTINGS_PATH)


func set_lang(l: String) -> void:
    lang = l
    _save_settings()
    language_changed.emit()


func set_music_vol(v: float) -> void:
    music_vol = clampf(v, 0.0, 1.0)
    _save_settings()
    volume_changed.emit()


func set_sfx_vol(v: float) -> void:
    sfx_vol = clampf(v, 0.0, 1.0)
    _save_settings()
    volume_changed.emit()


func set_fullscreen(v: bool) -> void:
    fullscreen = v
    _save_settings()
    _apply_fullscreen()


func _apply_fullscreen(restore_window := true) -> void:
    if fullscreen:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        return
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    if not restore_window:
        return
    # back to the 1280x720 window, centered on the current screen
    var win := Vector2i(1280, 720)
    var scr := DisplayServer.window_get_current_screen()
    var scr_size := DisplayServer.screen_get_size(scr)
    if scr_size.x >= win.x and scr_size.y >= win.y:
        DisplayServer.window_set_size(win)
        DisplayServer.window_set_position(DisplayServer.screen_get_position(scr) + (scr_size - win) / 2)


func t(key: String, args: Array = []) -> String:
    if not S.has(key):
        return key
    var pair: Array = S[key]
    var s: String = pair[1] if lang == "tr" else pair[0]
    if args.size() > 0:
        return s % args
    return s

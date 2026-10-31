# COP31 (Godot 4.x)

1. Godot 4.2+ ile `project.godot` dosyasını aç, F5.
2. Kontroller: A/D hareket, Boşluk/W zıpla, J/X saldır, B envanter. Çöp türlerini (cam/metal/kağıt/plastik) doğru kutulara götür, boss kapısının kilidini aç. Sinematiği Esc ile atlayabilirsin.
3. Sprite'lar `assets/` içinde. Geri dönüşüm kutuları `assets/<Tür>RecycleBin-Sheet.png` adıyla otomatik kullanılır (Plastic hazır; Glass, Metal, Paper eklenince kendiliğinden devreye girer, yoksa kodla çizilir).
4. Kalan her şey (oyuncu, düşmanlar, boss, sinematik, arka plan) şimdilik kodla çizilir; `_draw()` yerine `Sprite2D` konabilir.

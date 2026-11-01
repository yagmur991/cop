extends RefCounted
# Central lookup for the PNG sprites in res://assets. Use: const SpritesS = preload("res://scripts/sprites.gd")

const HEROES := [
    preload("res://assets/Gren.png"),     # char 0 (green)
    preload("res://assets/Blu.png"),      # char 1 (blue)
    preload("res://assets/Yello.png"),    # char 2 (yellow)
    preload("res://assets/Purp.png"),     # char 3 (purple)
    preload("res://assets/Pinkie.png"),   # char 4 (pink)
]
const ENEMY: Texture2D = preload("res://assets/Basic Monster.png")
const BOSSES := {
    "plastic": preload("res://assets/Boss 1.png"),
    "factory": preload("res://assets/Boss 2.png"),
    "land": preload("res://assets/Boss 3.png"),
}
const BINS := {
    "glass": preload("res://assets/Recycle bin glass.png"),
    "metal": preload("res://assets/Recycle bin metal.png"),
    "paper": preload("res://assets/Recycle Bin Paper.png"),
    "plastic": preload("res://assets/Recycle bin plastic.png"),
}
const GAIA := [
    preload("res://assets/gaia_01.png"),  # worried
    preload("res://assets/gaia_02.png"),  # happy
]

const FLASH_SHADER_CODE := "
shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    // COLOR already holds texture * modulate here
    COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash);
}
"
static var _flash_shader: Shader


static func hero(i: int) -> Texture2D:
    return HEROES[clampi(i, 0, HEROES.size() - 1)]


# Pixel-art sprite: crisp scaling. `bottom_center` = true puts the origin at the sprite's bottom middle.
static func make(tex: Texture2D, scl: float = 1.0, bottom_center: bool = true) -> Sprite2D:
    var s := Sprite2D.new()
    s.texture = tex
    s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    s.show_behind_parent = true   # parent's _draw() (prompts, icons, flashes) stays on top of the sprite
    s.scale = Vector2(scl, scl)
    if bottom_center:
        s.centered = false
        s.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
    return s


# White hit-flash material (set shader parameter "flash" 0..1).
static func flash_material() -> ShaderMaterial:
    if _flash_shader == null:
        _flash_shader = Shader.new()
        _flash_shader.code = FLASH_SHADER_CODE
    var m := ShaderMaterial.new()
    m.shader = _flash_shader
    return m

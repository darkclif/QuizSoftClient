extends Control

func _ready():
	init(0)

func init(icon_id):
	$Icon.texture = ResourceManager.get_icon_atlas(icon_id)

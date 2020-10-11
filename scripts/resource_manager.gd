extends Node

var IconsTexture = preload("res://resources/icons/icons.png")
var ICON_SIZE = 200
var ICONS_PER_ROW = 5
var ICONS_COUNT = 10

func get_icon_atlas(icon_id):
	var CorrectId = int(max(0, min(ICONS_COUNT - 1, icon_id)))
	
	if CorrectId != icon_id:
		print("Wrong icon id!")
	
	var NewAtlas = AtlasTexture.new()
	
	NewAtlas.atlas = IconsTexture
	NewAtlas.region = Rect2(
		(CorrectId % ICONS_PER_ROW) * ICON_SIZE,
		(CorrectId / ICONS_PER_ROW) * ICON_SIZE,
		ICON_SIZE,
		ICON_SIZE
	)
	
	return NewAtlas


func _ready():
	pass 

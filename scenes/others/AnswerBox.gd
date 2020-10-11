extends NinePatchRect

var BAD_COLOR = Color8(255, 150, 158, 255)
var GOOD_COLOR = Color8(178, 255, 150, 255)
var SELECTED_COLOR = Color8(150, 190, 255, 255)

var IsSure = false
var WasSelected = false

func _ready():
	self.mouse_filter = Control.MOUSE_FILTER_PASS

func set_text(text):
	$labText.text = text

func click_on_answer():
	if IsSure:
		self.set_selected()
		self.WasSelected = true
		$labSure.visible = false
		return true
	else:
		$labSure.visible = true
		self.IsSure = true
		return false

func clear_sure_mode():
	self.IsSure = false
	$labSure.visible = false

#
#	COLORS
#
func set_selected():
	self.modulate = SELECTED_COLOR

func set_correct():
	if self.WasSelected:
		$labGood.visible = true
	self.modulate = GOOD_COLOR
		
func set_uncorrect():
	if self.WasSelected:
		$labBad.visible = true
	self.modulate = BAD_COLOR

	

extends Control
class_name UpdateInfo

enum UpdateInfoMode {
	CONNECTION 	= 1,
	UPDATE_INFO = 2
}

var CurrectIconId = 0
var IconsRefs = []
var Mode = null

#
#	BASE
#
func _ready():
	$labAccept.mouse_filter = Control.MOUSE_FILTER_PASS
	$labBack.mouse_filter = Control.MOUSE_FILTER_PASS

	# Events
	GameState.connect("LOGIC_QUESTION_RECEIVED", self, "_on_question_arrived")

	# Fill current data
	if GameState.playerData.playerCreated:
		self.CurrectIconId = GameState.playerData.playerIconId
		$ChoosenIcon.init(self.CurrectIconId)
		$TextEdit.text = GameState.playerData.playerName
	else:
		$ChoosenIcon.init(self.CurrectIconId)

	# Spawn icons and attach callbacks
	self.IconsRefs = [
		$IconBox/Icon1,
		$IconBox/Icon2,
		$IconBox/Icon3,
		$IconBox/Icon4,
		$IconBox/Icon5,
		$IconBox/Icon6,
		$IconBox/Icon7,
		$IconBox/Icon8,
		$IconBox/Icon9,
		$IconBox/Icon10,
	]
	
	var i = 0
	for icon in IconsRefs:
		icon.init(i)
		icon.connect("gui_input", self, "_on_icon_click", [i])
		
		i += 1
		

####################################################################
#	PUBLIC
####################################################################
func init(mode):
	self.Mode = mode
	if mode == UpdateInfoMode.CONNECTION:
		pass
	elif mode == UpdateInfoMode.UPDATE_INFO:
		$labBack.visible = true
	else:
		GameState.add_console_line("Wrong mode on UpdateInfo scene initialization")

#
#	LOGIC
#
func _accept():
	if !self.check_data_correctness():
		return false
	
	var Nick = $TextEdit.text
	var IconId = self.CurrectIconId
		
	if GameState.update_player_info(Nick, IconId):
		return true
	else:
		$labInfoBottom.text = "Can't update player info due to network error."
		return false

func check_data_correctness():
	if $TextEdit.text.length() < 3 or $TextEdit.text.length() > 12:
		$labInfoBottom.text = "Nick length should be between 3 and 12 characters!"
		return false
		
	if self.CurrectIconId < 0 or self.CurrectIconId > 9:
		$labInfoBottom.text = "Bad icon choosen!"
		return false
	
	return true

#
#	HANDLERS
#
func _on_icon_click(event, icon_id):
	# Change icons handler
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		$ChoosenIcon.init(icon_id)
		self.CurrectIconId = icon_id

func _on_accept(event):
	# Accept profile change ('info_update')
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if !self._accept():
			GameState.add_console_line("[UpdateInfo] Update player info failed.")
		else:
			GameState.add_console_line("[UpdateInfo] Update player info sent properly.")
			
			# Swap scene
			self.queue_free()
			GameState.transition_updateinfo_to_lobby()
		
func _on_back(event):
	# Refuse profile change and do not send a packet
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		self.queue_free()
		GameState.transition_updateinfo_to_lobby()

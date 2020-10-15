extends Control

####################################################################
#	BASE
####################################################################
func _ready():
	# Events
	GameState.connect("LOGIC_QUESTION_RECEIVED", self, "_on_question_arrived")
	GameState.connect("LOGIC_PLAYER_INFO_REFRESHED", self, "_on_player_info_update")
	
	# Init player icon and name
	if GameState.playerData.playerCreated:
		$conPlayerIcon.init(GameState.playerData.playerIconId)
		$labPlayerName.text = GameState.playerData.playerName

####################################################################
#	LOGIC
####################################################################
func _on_question_arrived(QuestionData):
	# Transition to question
	self.queue_free()
	GameState.transition_lobby_to_question()
	
func _on_player_info_update():
	$conPlayerIcon.init(GameState.playerData.playerIconId)
	$labPlayerName.text = GameState.playerData.playerName

####################################################################
#	BUTTONS
####################################################################
func _on_profile_edit(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		GameState.transition_lobby_to_updateinfo()

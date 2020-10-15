extends Control

####################################################################
#	BASE
####################################################################
func _ready():
	# Events
	GameState.connect("LOGIC_QUESTION_RECEIVED", self, "_on_question_arrived")
	
####################################################################
#	LOGIC
####################################################################
func _on_question_arrived(QuestionData):
	# Transition to question
	self.queue_free()
	GameState.transition_waiting_to_question()

####################################################################
#	BUTTONS
####################################################################
func _on_TextureButton_pressed():
	GameState.player_ready_send()
	$btnReady.disabled = true

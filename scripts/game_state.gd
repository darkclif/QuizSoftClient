extends Node

# Scenes
const playerDataRes = preload("res://scripts/player_data.gd")
const sceneSettingsRes = preload("res://scenes/settings.tscn")

# Signals
signal LOGIC_QUESTION_RECEIVED(dict)
signal LOGIC_CORRECT_ANSWER_RECEIVED(dict)
signal LOGIC_CONNECTION_ACCEPT(dict)
signal LOGIC_CONNECTION_ACCEPT_RECONNECT(dict)
signal LOGIC_YOU_ARE_HERE_RECEIVED(dict)

signal LOGIC_PLAYER_INFO_REFRESHED()

# Current state
enum GameState {
	NOT_CONNECTED = 1,
	CONNECTED = 2,
	TODO = 3
}

var CurrentGameState = GameState.NOT_CONNECTED

# Data
var playerData = null
var sceneSettings = null

# Question format:
#{
#	"id": int_id
#	"question": "",
#	"answers": [4 : String]
#}

####################################################################
#	MAIN
####################################################################
func _ready():
	self.sceneSettings = sceneSettingsRes.instance()
	self.playerData = playerDataRes.new()
	
	NetworkState.connect("PCK_SERVER_CONNECTED", self, "_on_server_connected")
	
	NetworkState.connect("PCK_CONNECTION_ACCEPT", self, "_on_connection_accept")
	NetworkState.connect("PCK_QUESTION_SEND", self, "_on_question_send")
	NetworkState.connect("PCK_QUESTION_CORRECT_ANSWER", self, "_on_question_correct_answer")
	NetworkState.connect("PCK_YOU_ARE_HERE", self, "_on_you_are_here")

func _process(delta):
	pass

####################################################################
#	PUBLIC
####################################################################
func add_console_line(line):
	self.sceneSettings.add_console_line(line)

####################################################################
#	SCENE TRANSITION
####################################################################
# Lobby -> Question
func transition_lobby_to_question(QuestionData):
	# Abort when transition from wrong state
	if CurrentGameState != GameState.TODO:
		return

####################################################################
#	NET SEND
####################################################################
func update_player_info(nick, icon_id):
	if !NetworkState.info_update_send(nick, icon_id):
		self.add_console_line("[LOGIC] Packet 'info_update' failed to sent.")
		return false
	
	playerData.change_player_info(nick, icon_id)
	self.emit_signal("LOGIC_PLAYER_INFO_REFRESHED")
	return true

func connection_want_send():
	if !NetworkState.connection_want_send():
		self.add_console_line("[LOGIC] Packet 'connection_want' failed to sent.")
		return false
	
	return true
	
func give_answer_send(question_id, answer_id):
	if !NetworkState.give_answer_send(question_id, answer_id):
		self.add_console_line("[LOGIC] Packet 'give_answer' failed to sent.")
		return false
	
	return true
	
####################################################################
#	NET HANDLERS
####################################################################
func _on_server_connected():
	if CurrentGameState == GameState.NOT_CONNECTED:
		self.CurrentGameState = GameState.CONNECTED


func _on_connection_accept(dict):
	if CurrentGameState == GameState.CONNECTED:
		if bool(dict['reconnect']):
			emit_signal("LOGIC_CONNECTION_ACCEPT_RECONNECT", dict)
			
			# Fill missing player info
			self.playerData.init(dict['player_id'], dict['nick'], dict['icon_id'])
		else:
			emit_signal("LOGIC_CONNECTION_ACCEPT", dict)
			
			# We have player info, fill the player id
			self.playerData.set_player_id(dict['player_id'])
		
		self.CurrentGameState = GameState.GAME_AWAITING


func _on_question_send(dict):
	var QuestionData = dict['question']
	self.emit_signal("LOGIC_QUESTION_RECEIVED", QuestionData)


func _on_question_correct_answer(dict):
	var QuestionId = dict['question_id']
	var AnswerId = dict['answer_id']
	
	self.emit_signal("LOGIC_CORRECT_ANSWER_RECEIVED", QuestionId, AnswerId)


func _on_you_are_here(dict):
	if self.CurrentGameState == GameState.LOST:
		#self.emit_signal("LOGIC_YOU_ARE_HERE_RECEIVED", data)
		pass

#
#	ADDITIONAL CHANGE STATE HANDLERS
#
func _on_player_answer(answer_id):
	if self.CurrentGameState == GameState.WAITING_FOR_ANSWER:
		self.CurrentGameState = GameState.QUESTION_ANSWERED



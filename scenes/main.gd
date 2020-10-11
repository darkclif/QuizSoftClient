extends Control

enum MainMenuState {
	IDLE,
	SEARCHING_SERVER_IP,
	TRYING_TO_CONNECT,
	CONNECTED,
	CONNECTION_ACCEPTED
}

var currState = MainMenuState.IDLE

# Reconnect timers
const 	udpTimerStart = 5.0
var 	udpTimer = 0.0
const 	udpMaxTry = 5
var 	udpTry = 0

# Strings
var strSearchingServer = "Searching for server ip"
var strCannotFindServerIP = "Cannot find server ip"
var strFoundServerIP = "Server found on ip %s"
var strTryingConnect = "Connecting to a server"
var strConnected = "TCP connection established"
var strConnectionAccepted = "Connection accepted!"

# Scenes
const UpdateInfoScene = preload("res://scenes/update_info.tscn")
const LobbyScene = preload("res://scenes/lobby.tscn")
var SkipUpdateInfo : bool = false

####################################################################
#	BASE
####################################################################
func _ready():
	$labNext.mouse_filter = Control.MOUSE_FILTER_PASS
	
	NetworkState.connect("PCK_I_AM_SERVER", self, "_i_am_server_received")
	NetworkState.connect("PCK_SERVER_CONNECTED", self, "_server_connected")
	
	GameState.connect("LOGIC_CONNECTION_ACCEPT", self, "_connection_accept_received")
	GameState.connect("LOGIC_CONNECTION_ACCEPT_RECONNECT", self, "_connection_accept_reconnect_received")
	
func _process(delta):
	if currState == MainMenuState.SEARCHING_SERVER_IP:
		# Connection logic
		udpTimer -= delta
		
		if udpTimer < 0.0:
			udpTimer = udpTimerStart
			udpTry += 1
			
			if udpTry <= udpMaxTry:
				NetworkState.where_server_send()
			else:
				currState = MainMenuState.IDLE
				$btnMain.disabled = false
				self.set_state_label(strCannotFindServerIP, false)
	elif currState == MainMenuState.TRYING_TO_CONNECT:
		NetworkState.should_connect_tcp(true)
		

####################################################################
#	LOGIC
####################################################################
func set_state_label(labelString, dots = true):
	$labState.add_message(labelString)
	$labState.set_dots(dots)

func _i_am_server_received(ip):
	if currState == MainMenuState.SEARCHING_SERVER_IP:
		currState = MainMenuState.TRYING_TO_CONNECT
		set_state_label(strFoundServerIP % ip)

func _server_connected():
	currState = MainMenuState.CONNECTED
	self.set_state_label(strConnected)
	GameState.connection_want_send()
	
func _connection_accept_received(dict):
	# We need to provide player info
	currState = MainMenuState.CONNECTION_ACCEPTED
	self.set_state_label(strConnectionAccepted, false)	
	$labNext.visible = true

func _connection_accept_reconnect_received(dict):
	SkipUpdateInfo = true # We can skip to lobby
	
	currState = MainMenuState.CONNECTION_ACCEPTED
	self.set_state_label(strConnectionAccepted, false)
	$labNext.visible = true

####################################################################
#	EVENTS
####################################################################
func _on_btnMain_pressed():
	if currState == MainMenuState.IDLE:
		udpTimer = 0.0
		udpTry = 0

		set_state_label(strSearchingServer, true)
		NetworkState.should_connect_udp(true)
		currState = MainMenuState.SEARCHING_SERVER_IP
		$btnMain.disabled = true

func _on_labNext_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if currState == MainMenuState.CONNECTION_ACCEPTED:
			if self.SkipUpdateInfo:
				var NewScene = LobbyScene.instance()
				get_tree().get_root().add_child(NewScene)
			else:
				var NewScene = UpdateInfoScene.instance()
				NewScene.init(1) # connection
				get_tree().get_root().add_child(NewScene)
		
####################################################################
#	DEBUG
####################################################################
func _on_btnSettings_pressed():
	get_tree().get_root().add_child(GameState.sceneSettings)

func _on_btnLocal_pressed():
	self.currState = MainMenuState.TRYING_TO_CONNECT

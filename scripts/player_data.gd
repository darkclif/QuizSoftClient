extends Node

# assigned by server
# if it is more than 0 that means we have been connected to a server
var playerId = -1 

var playerCreated = false
var playerName = ''
var playerIconId = -1

var playerPoints = 0

func _ready():
	pass

####################################################################
#	PUBLIC
####################################################################
func init(id, nick, icon_id):
	self.playerCreated = true

	self.playerId = id
	self.playerName = nick
	self.playerIconId = icon_id

func change_player_info(nick, icon_id):
	self.playerCreated = true
	self.playerName = nick
	self.playerIconId = icon_id
	
func set_player_id(id):	
	self.playerId = id


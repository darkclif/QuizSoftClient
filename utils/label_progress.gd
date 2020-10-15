extends Label

# Settings
const MIN_SHOW_TIME = 1.0 # minimum time of showing message
const DOTS_CHANGE_TIME = 0.6 # dots change interval
const DOTS = ['.', '..', '...']

# Data
var dotTimer = DOTS_CHANGE_TIME
var showTimer = MIN_SHOW_TIME

var dotIndex = 0
var arrMessages = []
var showDots = true

func _ready():
	pass

func _process(delta):
	if arrMessages.size() == 0:
		return
	
	if showDots:
		if dotTimer > 0.0:
			dotTimer -= delta
		else:
			dotTimer = DOTS_CHANGE_TIME
			dotIndex = (dotIndex + 1) % DOTS.size()
		
			self.text = arrMessages[0] + DOTS[dotIndex] 
	
	if showTimer > 0.0:
		showTimer -= delta
	else:
		if arrMessages.size() > 1:
			showTimer = MIN_SHOW_TIME
			
			arrMessages.pop_front()
			dotIndex = 0
			self.text = arrMessages[0] + (DOTS[dotIndex] if showDots else '')

#
#	PUBLIC
#
func set_dots(flag):
	self.showDots = flag

func add_message(msg):
	arrMessages.push_back(msg)
	
	if arrMessages.size() == 1:
		self.text = arrMessages[0] + DOTS[dotIndex] 

func is_finished():
	return (showTimer <= 0.0 or arrMessages.size() == 0 )

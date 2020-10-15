extends Node

# Signals for incoming packets
signal PCK_I_AM_SERVER(server_ip) 	# UDP
signal PCK_SERVER_CONNECTED()		# TCP Connection Established

signal PCK_PING(dict)
signal PCK_PING_REQ(dict)
signal PCK_CONNECTION_ACCEPT(dict)
signal PCK_QUESTION_SEND(dict)
signal PCK_QUESTION_CORRECT_ANSWER(dict)
signal PCK_YOU_ARE_HERE(dict)

# UDP States
enum UDPState {
	OFF				= 1,
	LISTENING		= 2,
	SERVER_FOUND 	= 3
}

# TCP States
enum TCPState {
	OFF 			= 1,
	LISTENING 		= 2
}

# Connection and server data
var serverIp = '127.0.0.1' # we dont know yet
var serverPort = 8001
var serverBroadCastPort = 8000

var socketUDP = PacketPeerUDP.new()
var socketUDPConnected = false
var socketUDPShouldConnect = false

var socketTCP = null
var socketTCPWrapper = null 
var socketTCPConnected = false
var socketTCPShouldConnect = false

# Other
var deviceFingerprint = OS.get_unique_id().md5_text().substr(0,16)

# Packet dispatch for incoming packets
var packetRoutingUDP = {
	"i_am_server": funcref(self, "i_am_server_handle")
}

var packetRoutingTCP = {
	"connection_accept": funcref(self, "connection_accept_handle"),
	"question_send": funcref(self, "question_send_handle"),
	"question_correct": funcref(self, "question_correct_answer_handle"),
	"you_are_here": funcref(self, "you_are_here_handle")
}

####################################################################
#	MAIN
####################################################################
func _ready():
	# Set UDP
	socketUDP.set_broadcast_enabled(true)
	
	# Set TCP
	self.socketTCP = StreamPeerTCP.new()
	self.socketTCP.set_no_delay(true)
	self.socketTCPWrapper = PacketPeerStream.new()
	self.socketTCPWrapper.set_stream_peer(socketTCP)
		
	# Log
	self.add_console_line(deviceFingerprint)

func _exit_tree():
	socketUDP.close()
	socketTCP.disconnect_from_host()
	
func _process(delta):
	# Check state
	if socketUDPConnected and not socketUDP.is_listening():
		socketUDPConnected = false
	
	if socketTCPConnected and not socketTCP.is_connected_to_host():
		add_console_line("TCP client disconnected from " + str(serverIp))
		socketTCPConnected = false
	
	# UDP
	if socketUDPShouldConnect and not socketUDPConnected:
		self.start_udp_server()
	
	if socketUDPConnected:
		self.udp_packet_handle()
	
	# TCP
	if socketTCPShouldConnect and not socketTCPConnected:
		# Check TCP status
		var Status = self.socketTCP.get_status()
		
		if Status == StreamPeerTCP.STATUS_CONNECTED:
			socketTCPConnected = true
			emit_signal("PCK_SERVER_CONNECTED")
		elif Status == StreamPeerTCP.STATUS_NONE or Status == StreamPeerTCP.STATUS_ERROR:
			self.connect_to_tcp_server()
		
	if socketTCPConnected:
		self.tcp_packet_handle()

####################################################################
#	PUBLIC
####################################################################
func add_console_line(line):
	GameState.add_console_line(line)

func should_connect_tcp(val):
	socketTCPShouldConnect = val
	
func should_connect_udp(val):
	socketUDPShouldConnect = val

####################################################################
#	PRIVATE LOGIC
####################################################################
func start_udp_server():
	if (socketUDP.listen(serverBroadCastPort) != OK):
		add_console_line("Error listening on port: " + str(serverBroadCastPort))
	else:
		add_console_line("Listening on port: " + str(serverBroadCastPort))
		socketUDPConnected = true

func udp_packet_handle():
	while socketUDP.get_available_packet_count() > 0:
		var string = socketUDP.get_packet().get_string_from_ascii()
		var ip = socketUDP.get_packet_ip()
		
		if packetRoutingUDP.has(string):
			add_console_line("[UDP] '" + string + "' from " + str(ip))
			packetRoutingUDP[string].call_func()
		else:
			add_console_line("[UDP] '" + string + "' from " + str(ip) + " (unhandled)")

func connect_to_tcp_server():
	if not serverIp:
		add_console_line("[TCP] Cannot connect to server. No IP adress provided.")
		socketTCPShouldConnect = false
		return
	
	var Result = socketTCP.connect_to_host(serverIp, serverPort)
	if Result != OK:
		add_console_line("[TCP] Failed to connect to " + str(serverIp))
	else:		
		# Here handle connection or reconnection
		add_console_line("[TCP] Client connecting to " + str(serverIp))
		
func tcp_packet_handle():
	while socketTCPWrapper.get_available_packet_count() > 0:
		var string = socketTCPWrapper.get_packet().get_string_from_utf8()
		var ip = socketTCPWrapper.get_stream_peer().get_connected_host()
		var resultJSON = JSON.parse(string)
	
		if resultJSON.error != OK:
			add_console_line('Cannot parse JSON from TCP packet.')
		else:
			var dict = resultJSON.result
			
			if dict.has('msg') and packetRoutingTCP.has(dict['msg']):
				add_console_line("[TCP] '" + string + "' from " + str(ip))
				packetRoutingTCP[dict['msg']].call_func(dict)
			else:
				add_console_line("[TCP] '" + string + "' from " + str(ip) + "(unhandled)")

func check_correct_fields(dict, fields):
	for f in fields:
		if !dict.has(f):
			return false
	return true

####################################################################
#	SEND
####################################################################
# UDP
func where_server_send(): 
	# Prepare packet
	socketUDP.set_dest_address("255.255.255.255", 8000)
	var pac = "where_server".to_ascii()
	socketUDP.put_packet(pac)
	
	# Log
	self.add_console_line("Sent 'where_server' message.")

# TCP
func connection_want_send():
	var Packet = {
		'msg': 'connection_want', 
		'device_id': deviceFingerprint
	}
	
	return self._send_packet_helper(Packet)

func info_update_send(nick, icon_id):
	var Packet = {
		'msg': 'info_update', 
		'nick': nick,
		'icon_id': icon_id
	}

	return self._send_packet_helper(Packet)
	
func give_answer_send(question_number, answer_number):
	var Packet = {
		'msg': 'give_answer', 
		'question_number': question_number, 
		'answer_number': answer_number
	}

	return self._send_packet_helper(Packet)
	
func player_ready_send():
	var Packet = {
		'msg': 'player_ready', 
	}

	return self._send_packet_helper(Packet)
		
func i_am_lost_send(player_id):
	var Packet = {
		'msg': 'give_answer', 
		'player_id': player_id
	}
	
	return self._send_packet_helper(Packet)

func _send_packet_helper(packet):
	if not socketTCPConnected:
		return false

	var PacketString = JSON.print(packet)
	socketTCPWrapper.put_packet(PacketString.to_utf8())
	
	# Log to console
	self.add_console_line("[TCP] Sent '%s' message." % (packet['msg']))
	return true

####################################################################
#	RECEIVE
####################################################################
# UDP
func i_am_server_handle():
	# We know where is the server
	self.serverIp = str(socketUDP.get_packet_ip())
		
	# Signal
	emit_signal("PCK_I_AM_SERVER", serverIp)
		
	# Log
	self.add_console_line("Server at " + self.serverIp)
	
# TCP
func connection_accept_handle(dict):
	var fields = ['player_id', 'reconnect']
	
	if self.check_correct_fields(dict, fields):
		emit_signal("PCK_CONNECTION_ACCEPT", dict)
	else:
		self.add_console_line("Missing packet fields in 'connection_accept'")
	
func question_send_handle(dict):
	var fields = ['question']
	
	if self.check_correct_fields(dict, fields):
		emit_signal("PCK_QUESTION_SEND", dict)
	else:
		self.add_console_line("Missing packet fields in 'question_send'")
	
func question_correct_answer_handle(dict):
	var fields = ['question_id', 'correct_id']
	
	if self.check_correct_fields(dict, fields):
		emit_signal("PCK_QUESTION_CORRECT_ANSWER", dict)
	else:
		self.add_console_line("Missing packet fields in 'question_correct_answer'")
	
func you_are_here_handle(dict):
	var fields = ['']
	
	if self.check_correct_fields(dict, fields):
		emit_signal("PCK_YOU_ARE_HERE", dict)
	else:
		self.add_console_line("Missing packet fields in 'you_are_here'")


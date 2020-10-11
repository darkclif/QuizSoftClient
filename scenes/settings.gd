extends Control

func _ready():
	pass 

func add_console_line(line):
	$console.add_line(line)

#
# LOGIC
#
func _on_btnStartTCP_pressed():
	NetworkState.should_connect_tcp(true)

func _on_btnStartUDP_pressed():
	NetworkState.should_connect_udp(true)

# UDP
func _on_btnBroadcast_pressed():
	NetworkState.where_server_send()

func _on_btnExit_pressed():
	get_tree().get_root().remove_child(self)

#
#	TCP_PACKETS
#	
func _on_btnConnectionWant_pressed():
	NetworkState.connection_want_send()

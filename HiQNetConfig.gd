static var config: Dictionary = {
	"auto_start": true,							## Automatically takes this device online at launch
	"ip_address": "192.168.1.70",					## Default IP addres
	"network_broadcast": "192.168.1.255",			## Default IP addres
	"device_number": randi_range(1, 2**16 - 1-1),	## Device Number
	"fetch_name_on_disco": true,					## Gets all remote device names as soon as they are found on the network
}

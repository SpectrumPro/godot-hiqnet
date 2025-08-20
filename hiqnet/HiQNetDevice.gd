# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetDevice extends Node
## Class to represent a device on the HiQNet network


## Emitted when the network state is changed
signal network_state_changed(new_state: NetworkState)

## Emitted when the last seen time was changed
signal last_seen_time_changed(time: float)


## The TCP/UDP port for HiQNet
const HIQNET_PORT: int = HQ.HIQNET_PORT

## Device number to use when sending a message to broadcast
const DEVICE_NUMBER_BROADCAST: int = HQ.DEVICE_NUMBER_BROADCAST

## Copy of HiQNetGetAttributes.AttributeID
const AttributeID: Dictionary[String, int] = HiQNetGetAttributes.AttributeID


## Represents the state of the HiQNet network connection
enum NetworkState {
	OFFLINE,						## No connection is active
	DISCOVERING,					## Searching for HiQNet devices on the network
	AWAITING_SESSION_RESPONSE,		## Waiting for a reply to a session request
	RESPONDING_TO_SESSION,			## Actively responding to a session request
	CONNECTED,						## Successfully connected to a HiQNet session
	USING_SESSIONLESS_COMMS,		## Communicating without a session via UDP
}


## -------------------
## Network Connections
## -------------------

## Current NetworkState
var _network_state: NetworkState = NetworkState.OFFLINE

## The UDP connection bound to the device
var _udp_peer: PacketPeerUDP = PacketPeerUDP.new()

## -----------
## Device Info
## -----------

## HiQNet Device Number of the remote device
var _device_number: int = 00000

## Serial number of the remote device
var _serial_number: PackedByteArray = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

## Max message size of the remote device
var _max_message_size: int = 0x00100000

## Keep alive time in ms
var _keep_alive_time: int = 10000

## MAC Address of the remote device
var _mac_address: PackedByteArray = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

## DHCP state of the remote device
var _dhcp: bool = false

## IP Address of the remote device
var _ip_address: PackedByteArray = [192, 168, 1, 1]

## Subnet mask of the remote device
var _subnet_mask: PackedByteArray = [0xff, 0xff, 0xff, 0x00]

## Network gateway of the remote device
var _gateway: PackedByteArray = [0x00, 0x00, 0x00, 0x00] 

## UNIX timestamp of when this device last send a discovery message to the local device
var _last_seen: float = 0


## Creates a new HiQNetDevice from a HiQNetDiscoInfo message
static func create_from_discovery(p_discovery: HiQNetDiscoInfo) -> HiQNetDevice:
	var device: HiQNetDevice = HiQNetDevice.new()
	
	device._device_number = p_discovery.source_device
	device._serial_number = p_discovery.serial_number
	device._max_message_size = p_discovery.max_size
	device._keep_alive_time = p_discovery.keep_alive
	device._mac_address = p_discovery.mac_address
	device._dhcp = p_discovery.dhcp
	device._ip_address = p_discovery.ip_address
	device._subnet_mask = p_discovery.subnet_mask
	device._gateway = p_discovery.gateway
	device._last_seen = Time.get_unix_time_from_system()
	device.connect_udp()
	
	return device


## Ready
func _ready() -> void:
	get_attributes([AttributeID.ClassName, AttributeID.NameString])


## Connects the UDP peer, returning ERR_ALREADY_EXISTS if it is already connected
func connect_udp() -> Error:
	if _udp_peer.is_socket_connected():
		return ERR_ALREADY_EXISTS
	
	return _udp_peer.connect_to_host(HiQNetHeader.bytes_to_ip(_ip_address), HIQNET_PORT)


## Disconnects the UDP peer
func disconnect_udp() -> bool:
	if not _udp_peer.is_socket_connected():
		return false
	
	_udp_peer.close()
	return true


## Sends a message to the remote device
func send_message_udp(p_message: HiQNetHeader) -> Error:
	return _udp_peer.put_packet(p_message.get_as_packet())


## Handles a HiQNet message that came from the remote device
func handle_message(p_message: HiQNetHeader) -> void:
	if not is_instance_valid(p_message) or p_message.source_device != _device_number:
		return
	
	match p_message.message_type:
		HiQNetHeader.MessageType.DiscoInfo:
			_last_seen = Time.get_unix_time_from_system()
			last_seen_time_changed.emit(_last_seen)
			
			print("Device was just seen")


## Auto fill the infomation in a HiQNetHeadder for sending to the remote device
func auto_full_headder(p_headder: HiQNetHeader, p_flags: HiQNetHeader.Flags = 0, p_dest_address: Array[int] = [0, 0, 0, 0], p_source_address: Array[int] = [0, 0, 0, 0]) -> HiQNetHeader:
	p_headder.source_device = HQ.get_device_number()
	p_headder.source_address = p_source_address
	p_headder.dest_device = _device_number
	p_headder.dest_address = p_dest_address
	p_headder.flags = p_flags
	
	return p_headder


## Gets attributes from the remote device
func get_attributes(p_attributes: Array[int]) -> Error:
	var message: HiQNetGetAttributes = auto_full_headder(HiQNetGetAttributes.new())
	
	for id: int in p_attributes:
		message.get_attributes[id] = HiQNetHeader.Parameter.new(id)
	
	return send_message_udp(message)


## Returns the HiQNet Device Number of the remote device
func get_device_number() -> int:
	return _device_number


## Returns the serial number of the remote device
func get_serial_number() -> PackedByteArray:
	return _serial_number


## Returns the max message size of the remote device
func get_max_message_size() -> int:
	return _max_message_size


## Returns the keep alive time in ms
func get_keep_alive_time() -> int:
	return _keep_alive_time


## Returns the MAC Address of the remote device
func get_mac_address() -> PackedByteArray:
	return _mac_address


## Returns the DHCP state of the remote device
func get_dhcp() -> bool:
	return _dhcp


## Returns the IP Address of the remote device
func get_ip_address() -> PackedByteArray:
	return _ip_address


## Returns the IP Address of the remote device as a string
func get_ip_address_string() -> String:
	return HiQNetHeader.bytes_to_ip(_ip_address)


## Returns the subnet mask of the remote device
func get_subnet_mask() -> PackedByteArray:
	return _subnet_mask


## Returns the subnet mask of the remote device as a string
func get_subnet_mask_string() -> String:
	return HiQNetHeader.bytes_to_ip(_subnet_mask)


## Returns the network gateway of the remote device
func get_gateway() -> PackedByteArray:
	return _gateway


## Returns the network gateway of the remote device as a string
func get_gateway_string() -> String:
	return HiQNetHeader.bytes_to_ip(_gateway)


## Returns the UNIX timestamp of when this device last sent a discovery message
func get_last_seen() -> float:
	return _last_seen


## Sets the current NetworkState
func _set_network_state(p_network_state: NetworkState) -> bool:
	if p_network_state == _network_state:
		return false
	
	_network_state = p_network_state
	network_state_changed.emit(_network_state)
	
	return true

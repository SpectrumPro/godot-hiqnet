# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetClient extends Node
## Global class for HiQNet device discovery


## Emitted when the network state is changed
signal network_state_changed(new_state: NetworkState)

## Emitted when the discovery state is changed
signal discovery_state_changed(new_state)


## The TCP/UDP port for HiQNet
const HIQNET_PORT: int = 3804


## Enum for the NetworkState
enum NetworkState {
	OFFLINE,			## Node is offline
	ONLINE				## Node is online
}

## Enum for the DiscoveryState
enum DiscoveryState {
	DISABLE,			## Don't send any discovery
	ONLY_REPLY,			## Only reply to discovery
	ENABLED,			## Send discovery at a set interval
}


## -------------------
## Network Connections
## -------------------

## Current network state
var _network_state: NetworkState = NetworkState.OFFLINE

## The PacketPeerUDP for TX/RX broadcast
var _udp_broadcast: PacketPeerUDP = PacketPeerUDP.new()

## IP Address of this device
var _ip_address: PackedByteArray = [127,0,0,1]

## Mac Address of this device
var _mac_address: PackedByteArray = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

## Subnet Mask of this device
var _subnet_mask: PackedByteArray = [0xff, 0xff, 0xff, 0x00]


## ----------------
## Discovery Config
## ----------------

## Discovery state
var _discovery_state: DiscoveryState = DiscoveryState.ENABLED

## Discovery time interval in seconds
var _discovery_interval: int = 1

## The Timer node used for discovery 
var _discovery_timer: Timer = Timer.new()


## -------------
## Device Config
## -------------

## HiQNet device number of this device
var _device_number: int = 11111

## Serial Number of this device
var _serial_number: int = 0x00000000000000000000000000000000


## Init
func _init() -> void:
	_device_number = randi_range(1, 65535)
	_udp_broadcast.set_broadcast_enabled(true)
	_udp_broadcast.set_dest_address("255.255.255.255", HIQNET_PORT)


## Ready
func _ready() -> void:
	_discovery_timer.wait_time = _discovery_interval
	_discovery_timer.autostart = true
	_discovery_timer.timeout.connect(send_discovery_broadcast)
	
	add_child(_discovery_timer)
	go_online()


## Process
func _process(delta: float) -> void:
	while _udp_broadcast.get_available_packet_count() > 0:
		var packet: PackedByteArray = _udp_broadcast.get_packet()
		var message: HiQNetHeader = HiQNetHeader.phrase_packet(packet)
		
		if message and message.source_device != _device_number:
			print("Found Device: ", message.source_device)


## Takes this HiQNetClient online
func go_online() -> bool:
	if _network_state == NetworkState.ONLINE:
		return false
	
	_udp_broadcast.bind(HIQNET_PORT)
	
	_set_network_state(NetworkState.ONLINE)
	return true


## Takes this HiQNetClient offline
func go_offline() -> bool:
	if _network_state == NetworkState.OFFLINE:
		return false
	
	_udp_broadcast.close()
	
	_set_network_state(NetworkState.OFFLINE)
	return true


## Sets the discovery state
func set_discovery_state(p_discovery_state: DiscoveryState) -> bool:
	if p_discovery_state == _discovery_state:
		return false
	
	_discovery_state = p_discovery_state
	discovery_state_changed.emit(_discovery_state)
	
	return true


## Auto fill the infomation in a HiQNetHeadder for sending to broadcast
func auto_full_headder_broadcast(p_headder: HiQNetHeader, p_flags: HiQNetHeader.Flags = 0) -> HiQNetHeader:
	p_headder.source_device = _device_number
	p_headder.source_address = [0, 0, 0, 0]
	p_headder.dest_device = 65535
	p_headder.dest_address = [0, 0, 0, 0]
	p_headder.flags = p_flags
	
	return p_headder


## Sends a discovery packet to broadcast
func send_discovery_broadcast() -> void:
	var disco: HiQNetDiscoInfo = auto_full_headder_broadcast(HiQNetDiscoInfo.new())
	
	disco.serial_number = _serial_number
	disco.mac_address = _mac_address
	disco.ip_address = _ip_address
	disco.subnet_mask = _subnet_mask
	
	_udp_broadcast.put_packet(disco.get_as_packet())


## Sets the current NetworkState
func _set_network_state(p_network_state: NetworkState) -> bool:
	if p_network_state == _network_state:
		return false
	
	_network_state = p_network_state
	network_state_changed.emit(_network_state)
	
	return true

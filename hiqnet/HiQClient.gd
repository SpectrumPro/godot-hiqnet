# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetClient extends Node
## Global class for HiQNet device discovery


## Emitted when the network state is changed
signal network_state_changed(new_state: NetworkState)


## Enum for the NetworkState
enum NetworkState {
	OFFLINE,			## Node is offline
	ONLINE				## Node is online
}


## Current network state
var _network_state: NetworkState = NetworkState.OFFLINE


## Takes this HiQNetClient online
func go_online() -> bool:
	if _network_state == NetworkState.ONLINE:
		return false
	
	_set_network_state(NetworkState.ONLINE)
	return true


## Takes this HiQNetClient offline
func go_offline() -> bool:
	if _network_state == NetworkState.OFFLINE:
		return false
	
	_set_network_state(NetworkState.OFFLINE)
	return true


## Sets the current NetworkState
func _set_network_state(p_network_state: NetworkState) -> bool:
	if p_network_state == _network_state:
		return false
	
	_network_state = p_network_state
	network_state_changed.emit(_network_state)
	
	return true

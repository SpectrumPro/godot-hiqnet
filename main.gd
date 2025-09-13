# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.


class_name UIMain extends Control
## Main UI panel


## The Tree to display all discovred devieds
@export var discovred_tree: Tree 


## Enum for tree columns
enum Columns {NAME, DEVICE_NUMBER, IP_ADDRESS, NETWORK_STATE}


## RefMap for TreeItem: HiQNetDevice
var _discovered_devices: RefMap = RefMap.new()

## Current selected device if any
var _selected_device: HiQNetDevice

## SignalGroup for all HiQNetDevices
var _device_connections: SignalGroup = SignalGroup.new([
	_on_device_network_state_changed,
	_on_device_name_changed
]).set_prefix("_on_device_")


## Ready
func _ready() -> void:
	discovred_tree.create_item()
	discovred_tree.columns = len(Columns)
	for column: int in Columns.values():
		discovred_tree.set_column_title(column, Columns.keys()[column].capitalize())
	
	HQ.device_discovered.connect(_on_device_discovred)


## Called when a HiQNetDevice is discovred on the network
func _on_device_discovred(p_device: HiQNetDevice) -> void:
	if _discovered_devices.has_right(p_device):
		return
	
	var item: TreeItem = discovred_tree.create_item()
	
	item.set_text(Columns.NAME, p_device.get_device_name())
	item.set_text(Columns.DEVICE_NUMBER, str(p_device.get_device_number()))
	item.set_text(Columns.IP_ADDRESS, p_device.get_ip_address_string())
	item.set_text(Columns.NETWORK_STATE, p_device.get_network_state_human())
	
	_device_connections.connect_object(p_device, true)
	_discovered_devices.map(item, p_device)


## Called when the network state is changed on a device
func _on_device_network_state_changed(p_network_state: HiQNetDevice.NetworkState, p_device: HiQNetDevice) -> void:
	_discovered_devices.right(p_device).set_text(Columns.NETWORK_STATE, p_device.get_network_state_human())


## Called when a device name is changed
func _on_device_name_changed(p_new_name: String, p_device: HiQNetDevice) -> void:
	_discovered_devices.right(p_device).set_text(Columns.NAME, p_new_name)


## Called when an item is selected in the tree
func _on_discovred_tree_item_selected() -> void:
	_selected_device = _discovered_devices.left(discovred_tree.get_selected())


## Called when nothing is selected
func _on_discovred_tree_nothing_selected() -> void:
	discovred_tree.deselect_all()
	_selected_device = null


## Called when the StartSession button is pressed
func _on_start_session_pressed() -> void:
	if _selected_device:
		_selected_device.start_session()


## Called when the EndSession button is pressed
func _on_end_session_pressed() -> void:
	if _selected_device:
		_selected_device.end_session()


## Called when the DisconnectTCP button is pressed
func _on_disconnect_tcp_pressed() -> void:
	if _selected_device:
		_selected_device.disconnect_tcp()


func _on_re_connect_tcp_pressed() -> void:
	if _selected_device:
		_selected_device.reconnect_tcp()

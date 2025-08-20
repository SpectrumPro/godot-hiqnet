# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.


class_name UIMain extends Control
## Main UI panel


## The Tree to display all discovred devieds
@export var discovred_tree: Tree 


## Enum for tree columns
enum Columns {NAME, DEVICE_NUMBER, IP_ADDRESS}


## RefMap for TreeItem: HiQNetDevice
var _discovered_devices: RefMap = RefMap.new()


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
	
	#item.set_text(Columns.NAME, p_device.)
	item.set_text(Columns.DEVICE_NUMBER, str(p_device.get_device_number()))
	item.set_text(Columns.IP_ADDRESS, p_device.get_ip_address_string())
	

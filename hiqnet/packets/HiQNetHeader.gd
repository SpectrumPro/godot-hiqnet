# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetHeader extends RefCounted
## Represents a HiQNet packet header and provides encoding/decoding utilities.


## HiQNet version
const HIQNET_VERSION: int = 2 


## Message type enum
enum MessageType {
	NONE						=-0x0001,  ## No Mesage specified
	DiscoInfo					= 0x0000,  ## Discovery information
	GoodBye						= 0x0007,  ## Goodbye message
	Hello						= 0x0008,  ## Hello message
	Locate						= 0x0129,  ## Locate message
	MultiParamSet				= 0x0100,  ## Multi parameter set
	MultiParamGet				= 0x0103,  ## Multi parameter get
	GetAttributes				= 0x010D,  ## Get attributes
	GetVDList					= 0x011A,  ## Get VD list
	ParameterSubscribeAll		= 0x0113,  ## Subscribe all parameters
	ParameterUnSubscribeAll		= 0x0114,  ## Unsubscribe all parameters
	Store						= 0x0124,  ## Store command
	Recall						= 0x0125## Recall command
}


## Data type enum
enum DataType {
	BYTE,						## Signed byte
	UBYTE,						## Unsigned byte
	WORD,						## Signed 16-bit
	UWORD,						## Unsigned 16-bit
	LONG,						## Signed 32-bit
	ULONG,						## Unsigned 32-bit
	FLOAT32,					## 32-bit float
	FLOAT64,					## 64-bit float
	BLOCK,						## Block of bytes
	STRING,						## String
	LONG64,						## Signed 64-bit
	ULONG64,					## Unsigned 64-bit
}


## Flags enum (bit positions)
enum Flags {
	REQUEST_ACK					= (1 << 0),  ## Request acknowledgment
	ACKNOWLEDGEMENT				= (1 << 1),  ## Acknowledgement flag
	INFORMATION					= (1 << 2),  ## Information flag
	ERROR						= (1 << 3),  ## Error flag
	GUARANTEED					= (1 << 5),  ## Guaranteed delivery
	MULTIPART					= (1 << 6),  ## Multipart message
	SESSION_NUMBER				= (1 << 8)## Session number included
}

## Matches the MessageType enum to a class
static var ClassTypes: Dictionary[int, Script] = {
	MessageType.DiscoInfo: HiQNetDiscoInfo
}


## HiQNet ID of this device
var source_device: int = 00000

## Source address of this device
var source_address: Array = [0, 0, 0, 0]  

## HiQNet ID of the destination device
var dest_device: int = 65535 

## Address of the destination device
var dest_address: Array = [0, 0, 0, 0] 

## Message type of this packet
var message_type: MessageType = MessageType.DiscoInfo  

## Bitmask of packet flags
var flags: int = 0  

## Number of network hops
var hop_count: int = 0x05 

## Packet debug sequence number
var sequence_number: int = 0x01 

## Session number if flag set
var session_number: int = 0  

## Error code (decode only)
var error_code: int = 0x02

## Error string (decode only)
var error_string: String = ""

## Start sequence number for multipart (decode only)
var start_seq_number: int = 0x02 

## Bytes remaining in multipart (decode only)
var bytes_remaining: int = 0  


## Creates a HiQNet header with the given message length
func get_as_packet() -> PackedByteArray:
	var header: PackedByteArray = PackedByteArray()
	var header_length: int = 25
	var message: PackedByteArray = _get_as_packet()
	var message_length: int = message.size()
	
	if (flags & Flags.SESSION_NUMBER) != 0:
		header_length += 2
	
	message_length += header_length
	
	header.append_array([HIQNET_VERSION])
	header.append(header_length)
	
	# Message length (4 bytes)
	header.append_array(ba(message_length, 4))
	
	# Source device and address
	header.append_array(ba(source_device, 2))
	header.append_array(source_address)
	
	# Destination device and address
	header.append_array(ba(dest_device, 2))
	header.append_array(dest_address)
	
	# Message type and flags
	header.append_array(ba(message_type, 2))
	header.append_array(ba(flags, 2))
	
	header.append_array([hop_count])
	header.append_array([0x00, sequence_number])
	
	# Session number if flag set
	if (flags & Flags.SESSION_NUMBER) != 0:
		header.append_array(ba(session_number, 2))
	
	header.append_array(message)
	return header


## Decodes header from a packet into a HiQNetHeader object
static func phrase_packet(p_packet: PackedByteArray) -> HiQNetHeader:
	if not is_packet_valid(p_packet):
		return null
	
	var p_message_type = (p_packet[18] << 8) | p_packet[19]
	var message: HiQNetHeader
	
	if p_message_type not in ClassTypes:
		return null
	
	message = ClassTypes[p_message_type].new()
	message.source_device = (p_packet[6] << 8) | p_packet[7]
	message.source_address = PackedByteArray(p_packet.slice(8, 12))
	
	message.dest_device = (p_packet[12] << 8) | p_packet[13]
	message.dest_address = PackedByteArray(p_packet.slice(14, 18))
	
	message.flags = (p_packet[20] << 8) | p_packet[21]
	message.hop_count = p_packet[22]
	message.sequence_number = (p_packet[23] << 8) | p_packet[24]
	
	var offset: int = 25
	
	if (message.flags & Flags.ERROR):
		var length: int = (p_packet[offset] << 8) | p_packet[offset + 1]
		offset += 2 + 2 + length
	
	if (message.flags & Flags.MULTIPART):
		offset += 6
	
	if (message.flags & Flags.SESSION_NUMBER):
		message.session_number = (p_packet[offset] << 8) | p_packet[offset + 1]
	
	message._phrase_packet(p_packet)
	return message


## Returns packet body (without header)
static func get_packet_body(packet: PackedByteArray) -> PackedByteArray:
	var header_length: int = packet[1]
	return packet.slice(header_length)


## Converts an integer to a PackedByteArray
static func ba(value: int, byte_count: int = 4) -> PackedByteArray:
	var packed: PackedByteArray = PackedByteArray()
	for i in range(byte_count):
		packed.append((value >> (8 * (byte_count - 1 - i))) & 0xFF)
	return packed


## Converts an IP string to a PackedByteArray
static func ip_to_bytes(ip: String) -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	for part: String in ip.split("."):
		bytes.append(int(part))
	return bytes


## Converts an IP byte array to a string
static func bytes_to_ip(bytes: PackedByteArray) -> String:
	var ip: String = ""
	for byte: int in bytes:
		ip += str(byte) + "."
	return ip.substr(0, ip.length() - 1)


## Checks if packet is valid
static func is_packet_valid(packet: PackedByteArray) -> bool:
	return packet.size() >= 25 and packet[0] == HIQNET_VERSION


## Decodes parameters from a packet
static func decode_parameters(packet: PackedByteArray) -> Dictionary[int, Array]:
	var parameters: Dictionary[int, Array] = {}
	var num_parameters: int = (packet[0] << 8) | packet[1]
	var offset: int = 2
	
	for i in range(num_parameters):
		var parameter_id: int = (packet[offset] << 8) | packet[offset + 1]
		offset += 2
		
		var data_type: int = packet[offset]
		offset += 1
		
		match data_type:
			DataType.STRING:
				var string_length: int = (packet[offset] << 8) | packet[offset + 1]
				offset += 2
				
				var result: String = ""
				for index in range(0, string_length, 2):
					result += char((packet[offset + index] << 8) | packet[offset + index + 1])
				
				offset += string_length
				parameters[parameter_id] = [DataType.STRING, result]
			
			DataType.BLOCK:
				var block_length: int = (packet[offset] << 8) | packet[offset + 1]
				offset += 2
				
				var block_value: PackedByteArray = packet.slice(offset, offset + block_length)
				offset += block_length
				
				parameters[parameter_id] = [DataType.BLOCK, block_value]
			
			DataType.LONG:
				var value: int = (packet[offset] << 24) | (packet[offset + 1] << 16) | (packet[offset + 2] << 8) | packet[offset + 3]
				offset += 4
				
				parameters[parameter_id] = [DataType.LONG, value]
	
	return parameters


## Override this function to provide a packet payload
func _get_as_packet() -> PackedByteArray:
	return []


## Override this function to provide a decode a packet
func _phrase_packet(p_packet: PackedByteArray) -> void:
	pass

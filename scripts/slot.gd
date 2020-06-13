tool
extends Control

"""
# EN_US: Exported variables
"""

# EN_US: Unique ID for the slot, for the dragged item, or for the slot to accept only other slots of that ID
export var uid = "" 

# EN_US: Accepts items in the same group
export var group = ""

# EN_US: Unit selection or regular slot
export(bool) var unitSelector = false

# EN_US: Item quantity, use with the "increment" variable
export(int) var qtd = 0 setget _setQtd 

# EN_US: Health quantity, use with the "increment" or "decrement" variable
export(int) var health = 3 setget _setHealth

# EN_US: Maximum amount for the slot, use with the "increment" variable
export(int) var maxQtd = 0 

# EN_US: Shows or hides the quantity counter
export(bool) var showQtd = true setget _setShowQtd 

# EN_US: Shows or hides the health counter
export(bool) var showHealth = true setget _setShowHealth 

# EN_US: Allows incremental control of the quantity
export(bool) var increment = true

# EN_US: Allows decremental control of the health
export(bool) var decrement = true 

# EN_US: Allows an item that has no image, overwrite the image of the slot where it is going
export(bool) var replaceNull = true 

# EN_US: Allows click to clear the slot
export(bool) var canClear = true 

# EN_US: Allows click to clear the slot
export(bool) var canReceive = true 

# EN_US: Preview transparency
export(float, 0.0, 1.0) var opacityPreview = .5 

# EN_US: Background color for slot
export(Color) var color: Color = Color(0.25,0.25,0.25,1) setget _setColor

# EN_US: Slot size
export(Vector2) var size: Vector2 = Vector2(64, 64) setget _setSize

# EN_US: Slot image
export(Texture) var image: Texture = null setget _setImage

# EN_US: Drag preview image
export(Texture) var imagePreview: Texture = null setget _setImagePreview

# EN_US: Local variables
var defaults: Dictionary = {}
var _mouseRightButton: bool = false
var isDragging: bool = false

# EN_US: setGet Functions
func _setShowQtd(newValue) -> void:
	showQtd = newValue
	if weakref($qtd).get_ref():
		$qtd.set("visible", showQtd)
func _setQtd(newValue) -> void:
	qtd = newValue
	if weakref($qtd).get_ref():
		$qtd.text = str(qtd)
func _setShowHealth(newValue) -> void:
	if unitSelector == true:
		# TODO: HIDE NUMBER HERE
		pass
	else:
		showHealth = newValue
		if weakref($health).get_ref():
			$health.set("visible", showHealth)
func _setHealth(newValue) -> void:
	health = newValue
	if weakref($health).get_ref():
		$health.text = str(health)
func _setColor(newValue) -> void:
	color = newValue
	if weakref($color).get_ref():
		$color.color = color
func _setImage(newValue) -> void:
	image = newValue
	if weakref($image).get_ref():
		$image.texture = image
func _setImagePreview(newValue) -> void:
	imagePreview = newValue
	if weakref($preview).get_ref():
		$preview.texture = imagePreview
func _setSize(newValue) -> void:
	size = newValue
	rect_min_size = size
	rect_size = size
	$color.rect_min_size = size
	$color.rect_size = size
	$image.rect_min_size = size
	$image.rect_size = size
	$preview.rect_min_size = size
	$preview.rect_size = size
	$qtd.rect_size.x = size.x - 10
	$health.rect_size.x = size.x - 10
	$touch.scale = (newValue * 64 / 2.0) / 1000.0

func _ready():
	defaults = {
		"color": color
	}
	
	# EN_US: It is necessary to put the mouse filter as ignore, otherwise the drag will not work
	# Set all children as MOUSE_FILTER_IGNORE
	for n in get_children():
		if "mouse_filter" in n:
			n.mouse_filter = MOUSE_FILTER_IGNORE


# EN_US: If the user clicks the right mouse button, or two fingers on the screen
# EN_US: Enables / Disables unit transfer of slots that increment
func _input(event) -> void:
	# EN_US: If you right-click
	if event is InputEventMouseButton:
		if event.button_index == 2 and event.is_pressed():
			if increment:
				_mouseRightButton = !_mouseRightButton
				$unit.set("visible", _mouseRightButton)

	# EN_US: If you touch the screen with both fingers
	if event is InputEventScreenTouch:
		if event.index == 1 and event.is_pressed():
			if increment:
				_mouseRightButton = !_mouseRightButton
				$unit.set("visible", _mouseRightButton)

# EN_US: A function to reset the slot
func _clearSlot() -> void:
	# EN_US: Sets the default values
	qtd = 0
	uid = ""
	$color.color = defaults["color"]
	$image.texture = null
	$qtd.text = str(qtd)
	$health.text = str(health)

# EN_US: A function for when the user clicks on the slot, to allow it to be cleaned, as long as the parameter "canClear" is "TRUE"
func _on_touch_pressed() -> void:
	if increment: return
	yield(get_tree().create_timer(.2), "timeout")
	if isDragging: return
	if !canClear: return
	_clearSlot()


""" 
DRAG AND DROP
"""

# EN_US: Function called automatically as soon as a drag action is identified
func get_drag_data(position):
	isDragging = true
	var previewPos = -($color.rect_size / 2)
	
	# EN_US(1): Preview of the dragged item, duplicating itself
	# EN_US(2): This duplicate item, only server for the preview, then it is automatically discarded
	var dragPreview = self.duplicate()
	dragPreview.modulate.a = opacityPreview
	dragPreview.get_node("color").rect_position = previewPos
	dragPreview.get_node("image").rect_position = previewPos
	dragPreview.get_node("preview").rect_position = previewPos
	dragPreview.get_node("touch").hide()
	dragPreview.get_node("qtd").hide()
	
	if dragPreview.image is Texture:
		dragPreview.get_node("color").hide()
	
	if dragPreview.imagePreview is Texture:
		dragPreview.get_node("preview").show()
		dragPreview.get_node("color").hide()
		dragPreview.get_node("image").hide()
	
	# EN_US: Build the preview
	set_drag_preview(dragPreview)
	
	# PR_BR: Retornar para o can_drag / drop
	# EN_US: Return to can_drag / drop
	return self

# EN_US: This function validates if there is an item being dragged over that node, it must return "TRUE" or "FALSE"
func can_drop_data(position, data) -> bool:
	if !canReceive: return false
	if data == self: return false
	var ret = false
	
	# EN_US: If the source slot has an option that is significantly different from the target slot
	if increment != data["increment"]:
		return false 

	# EN_US: If the slot is incremental
	if increment:
		# EN_US: If the dragged slot is empty
		if data["qtd"] == 0:
			return false
			
		# EN_US: If the slot has a maximum limit, and is already fully occupied
		if maxQtd != 0 and maxQtd == qtd:
			return false

		# EN_US: If the source and destination have the same uid, or the slot has no uid
		if data["uid"] == uid or uid == "":
			ret = true

	else:
		# EN_US: If origin and destination are from the same group, or the slot has no group
		if ((data["group"] == group) or (group == "")):
			ret = true
			
	return ret

# EN_US: This function captures the preview that was being dragged, and comes in the parameter "data"
func drop_data(position, data) -> void:
	var qtdDrop = 0
	
	# EN_US: If the slot is of the increment type
	if increment:
		# EN_US: If you have unit mode enabled
		if _mouseRightButton:
			qtdDrop = 1
			# EN_US: If the slot has a maximum limit
			if maxQtd > 0:
				qtdDrop = clamp(1, 0, abs(maxQtd - qtd))
		else:
			qtdDrop = data["qtd"]
			# EN_US: If it has a maximum limit, then limit the dropped value
			if maxQtd > 0:
				qtdDrop = clamp(data["qtd"], 1, abs(maxQtd - qtd))
		
		# EN_US: Increase the amount
		qtd += qtdDrop 
		
		# EN_US: Updates the slid uid
		uid = data["uid"] 
	
	# EN_US: Updates the image, color and quantity of the slot that received the item
	image = data["image"] 
	$color.color = data["color"]
	$qtd.text = str(qtd)
	
	# EN_US: If the dropped image has a texture
	if data["image"] is Texture:
		# EN_US: Updates the slot texture
		$image.texture = data["image"] 
	else:
		# EN_US: If checked to clear in case of null image
		if replaceNull: 
			$image.texture = null
			
	# EN_US: Updates information on the source object
	if data.increment:
		# EN_US: Decreases the amount dropped
		data["qtd"] -= qtdDrop 
		
		# EN_US: If the quantity is 0, clean the original slot
		if data["qtd"] == 0:
			data._clearSlot()
			
		# EN_US: Updates the quantity label
		data.get_node("qtd").text = str(data["qtd"])
	
	# EN_US: Updates the variable in the dropped object (source)
	data.isDragging = false


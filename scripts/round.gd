extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _pressed():
	print("-- STARTING NEXT ROUND --")
	# Build enemy slots
	#
	var enemySlots = _buildEnemySlots()

	
	# Handle round fights
	#
	var slots = get_tree().current_scene.get_node("slots").get_children()
	for i in range(slots.size()):
		_handle_slot(slots[i], enemySlots[i])

				
#	for slot in slots:
#		_handle_slot(slot, enemySlots)
		
	# Check if game is over
	#
	# TODO
	
	# Reset for next round
	#
	
	# Reset selections
	# TODO: don't hard code this stuff
	var unitSelection = get_tree().current_scene.get_node("unitSelection").get_children()
	var helmUnit = unitSelection[0]
	helmUnit.uid = "helm"
	helmUnit.qtd = 5
	_resetTexture(helmUnit)

	var swordUnit = unitSelection[1]
	swordUnit.uid = "sword"
	swordUnit.qtd = 5
	_resetTexture(swordUnit)
	
	var appleUnit = unitSelection[2]
	appleUnit.uid = "apple"
	appleUnit.qtd = 5
	_resetTexture(appleUnit)

func _buildEnemySlots():
	var units = [
		{"helm": 3},
		{"sword": 3},
		{"apple": 3}
	]
	var enemySlots = []
	for enemy in range(8):
		# Type
		var chosenUnit = units[randi() % units.size()]
		print(chosenUnit)
		var unitType = chosenUnit.keys()[0]
		var unitQtd = chosenUnit.values()[0]
		
		# Count
		var chosenCount = randi() % unitQtd
		if chosenCount == 0:
			enemySlots.append({
				"uid": null,
				"qtd": 0
			})
		else:
			var enemySlot = {
				"uid": unitType,
				"qtd": chosenCount
			}
			enemySlots.append(enemySlot)
		
	return enemySlots
	
func _handle_slot(slot, enemySlot):
	print(slot, enemySlot)
	# User slot
	var user_atk = 0
	var user_def = 0
	if slot.uid == "helm":
		user_def += slot.qtd
	if slot.uid == "sword":
		user_atk += slot.qtd

	# Enemy slot
	var enemy_atk = 0
	var enemy_def = 0
	if enemySlot.uid == "helm":
		enemy_atk += enemySlot.qtd
	if enemySlot.uid == "sword":
		enemy_def += enemySlot.qtd
		
	# Fight
	var user_taking_damage = (enemy_atk - user_def)
	var enemy_taking_damage = (user_atk - enemy_def)
	print("User damage -> " + str(user_taking_damage))
	print("Enemy damage -> " + str(enemy_taking_damage))
	
	if user_taking_damage > 0:
		slot.health -= user_taking_damage
	
	# Healing stage
	if slot.uid == "apple" and slot.health > 0:
		slot.health += slot.qtd
		
	if slot.health <= 0:
		slot.is_dead = true

	# Reset
	slot._clearSlot()
		
func _resetTexture(selection):
	var texturePath = "res://assets/itens/%s.png" % selection.uid
	selection.image = load(texturePath)

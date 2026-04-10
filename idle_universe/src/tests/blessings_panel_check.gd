extends SceneTree

const GameStateScript = preload("res://src/core/game_state.gd")
const BlessingsPanelControllerScript = preload("res://src/controllers/blessings_panel_controller.gd")

func _initialize() -> void:
	var state: GameState = GameStateScript.from_content(
		_load_json("res://src/data/elements.json"),
		_load_json("res://src/data/upgrades.json"),
		_load_json("res://src/data/blessings.json"),
		_load_json("res://src/data/planets.json"),
		_load_json("res://src/data/planet_menu.json")
	)
	state.blessings_menu_unlocked = true

	var panel := VBoxContainer.new()
	panel.visible = true
	var title := Label.new()
	var info := Label.new()
	panel.add_child(title)
	panel.add_child(info)

	var controller = BlessingsPanelControllerScript.new()
	controller.configure(panel, info)
	controller.refresh_progress(state)
	controller.refresh_catalog(state)

	var scroll := panel.get_node_or_null("BlessingsScroll") as ScrollContainer
	if scroll == null:
		_fail("Blessings scroll was not created.")
		return
	var section_list := scroll.get_node_or_null("BlessingsSectionList") as VBoxContainer
	if section_list == null:
		_fail("Blessings section list was not created.")
		return
	if section_list.get_child_count() != state.get_blessing_rarity_order().size():
		_fail("Blessing rarity sections did not match the blessing data.")
		return

	var row_count := 0
	for section_variant in section_list.get_children():
		var section := section_variant as VBoxContainer
		if section == null or section.get_child_count() != 2:
			_fail("Blessing section layout is malformed.")
			return
		var rows_box := section.get_child(1) as VBoxContainer
		if rows_box == null:
			_fail("Blessing section rows container is missing.")
			return
		row_count += rows_box.get_child_count()
	if row_count != state.get_blessing_ids().size():
		_fail("Blessing catalog row count did not match the blessing data.")
		return

	var initial_child_count := _count_children(panel)
	controller.refresh_progress(state)
	controller.refresh_catalog(state)
	if _count_children(panel) != initial_child_count:
		_fail("Blessing refresh rebuilt the catalog tree.")
		return

	state.unopened_blessings_count = 1
	if state.open_earned_blessings() != 1:
		_fail("Opening a test blessing failed.")
		return
	controller.refresh_progress(state)
	controller.refresh_catalog(state)
	if _count_children(panel) != initial_child_count:
		_fail("Opening blessings rebuilt the catalog tree.")
		return

	print("Blessings panel check passed.")
	quit()

func _count_children(node: Node) -> int:
	var total := node.get_child_count()
	for child in node.get_children():
		total += _count_children(child)
	return total

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Missing JSON file %s." % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("Expected dictionary JSON at %s." % path)
		return {}
	return parsed

func _fail(message: String) -> void:
	push_error("Blessings panel check failed: %s" % message)
	quit(1)

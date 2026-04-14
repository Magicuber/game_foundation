extends SceneTree

const TestSupportScript = preload("res://src/tests/test_support.gd")
const UpgradesSystemScript = preload("res://src/systems/upgrades_system.gd")
const ElementSystemScript = preload("res://src/systems/element_system.gd")
const DustRecipeServiceScript = preload("res://src/services/dust_recipe_service.gd")
const OUTPUT_PATH := "res://src/tests/core_regression_suite_report.txt"

var _passed := 0
var _failed := 0
var _failures: Array[String] = []
var _log_lines: Array[String] = []

func _initialize() -> void:
	_run_case("save_roundtrip", Callable(self, "_test_save_roundtrip"))
	_run_case("progression_state", Callable(self, "_test_progression_state"))
	_run_case("upgrade_aggregate", Callable(self, "_test_upgrade_aggregate"))
	_run_case("dust_recipe", Callable(self, "_test_dust_recipe"))
	_run_case("planet_production", Callable(self, "_test_planet_production"))
	_run_case("element_system", Callable(self, "_test_element_system"))
	_run_case("fission_overflow_base_output", Callable(self, "_test_fission_overflow_base_output"))

	if _failed == 0:
		var pass_message := "Core regression suite passed (%d/%d)." % [_passed, _passed]
		_log_lines.append(pass_message)
		print(pass_message)
		_write_report()
		quit()
		return

	for failure in _failures:
		_log_lines.append(failure)
		push_error(failure)
	var failure_summary := "Core regression suite failed (%d passed, %d failed)." % [_passed, _failed]
	_log_lines.append(failure_summary)
	push_error(failure_summary)
	_write_report()
	quit(1)

func _run_case(name: String, test_callable: Callable) -> void:
	var failure := str(test_callable.call())
	if failure.is_empty():
		_passed += 1
		var pass_line := "PASS %s" % name
		_log_lines.append(pass_line)
		print(pass_line)
		return

	_failed += 1
	_failures.append("FAIL %s: %s" % [name, failure])

func _write_report() -> void:
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write regression suite report to %s." % OUTPUT_PATH)
		return
	file.store_string("\n".join(_log_lines))
	file.flush()

func _test_save_roundtrip() -> String:
	var state: GameState = TestSupportScript.build_state()
	TestSupportScript.unlock_elements(state, ["ele_H", "ele_He", "ele_Ne", "ele_Na"])
	TestSupportScript.set_element_amount(state, "ele_H", 1234.0)
	TestSupportScript.set_element_amount(state, "ele_He", 222.0)
	TestSupportScript.set_element_amount(state, "ele_Na", 15000.0)
	state.get_element_state("ele_Ne").show_in_counter = true
	state.orbs = 321
	state.dust = DigitMaster.new(6543.0)
	state.current_element_id = "ele_He"
	state.unlocked_era_index = 1
	state.research_points = DigitMaster.new(27.0)
	state.research_progress = 0.5
	state.total_manual_smashes = 9
	state.total_auto_smashes = 4
	state.completed_milestones = ["planet_a_5"]
	state.next_milestone_id = "planet_b_5"
	state.oblation_claimed_recipe_ids = ["hydrogen_memory", "helium_study"]
	state.best_planet_levels_this_run["planet_a"] = 5
	state.planet_purchase_unlocks["planet_a"] = true
	state.planet_purchase_unlocks["planet_b"] = true
	state.planet_owned_flags["planet_a"] = true
	state.planet_owned_flags["planet_b"] = true
	state.sacrificed_planet_flags["planet_b"] = false
	state.moon_upgrade_purchases["moon_b_1"] = ["slot_1"]

	state.set_upgrade_level("particle_smasher", 3)
	state.set_upgrade_current_cost("particle_smasher", DigitMaster.new(17.0))
	state.set_upgrade_level("critical_smasher_chance_2", 2)
	state.set_upgrade_current_cost("critical_smasher_chance_2", DigitMaster.new(900.0))
	state.set_upgrade_secondary_current_cost("critical_smasher_chance_2", DigitMaster.new(4500.0))

	var planet_a := state.get_planet_state("planet_a")
	if planet_a == null:
		return "Planet A missing from test state."
	planet_a.unlocked = true
	planet_a.level = 4
	planet_a.workers = DigitMaster.new(12.0)
	planet_a.xp = DigitMaster.new(345.0)
	planet_a.worker_allocation_to_xp = 0.25
	planet_a.xp_to_next_level = state._calculate_planet_xp_requirement(planet_a.level)
	state.current_planet_id = "planet_a"
	state.refresh_progression_state()

	var save_data := state.to_save_dict()
	var loaded_state: GameState = TestSupportScript.build_state()
	loaded_state.apply_save_dict(save_data)

	if loaded_state.orbs != 321:
		return "Orbs did not survive round-trip."
	if not TestSupportScript.digit_equals(loaded_state.dust, DigitMaster.new(6543.0)):
		return "Dust did not survive round-trip."
	if loaded_state.current_element_id != "ele_He":
		return "Current element id did not survive round-trip."
	if not loaded_state.is_element_unlocked("ele_Ne"):
		return "Unlocked element state did not survive round-trip."
	if not TestSupportScript.digit_equals(loaded_state.get_resource_amount("ele_H"), DigitMaster.new(1234.0)):
		return "Element amount did not survive round-trip."
	if loaded_state.get_upgrade_state("particle_smasher").current_level != 3:
		return "Primary upgrade level did not survive round-trip."
	if not TestSupportScript.digit_equals(
		loaded_state.get_upgrade_state("critical_smasher_chance_2").secondary_current_cost,
		DigitMaster.new(4500.0)
	):
		return "Secondary upgrade cost did not survive round-trip."
	if loaded_state.get_planet_state("planet_a").level != 4:
		return "Planet level did not survive round-trip."
	if not TestSupportScript.digit_equals(loaded_state.get_planet_state("planet_a").workers, DigitMaster.new(12.0)):
		return "Planet workers did not survive round-trip."
	if loaded_state.get_visible_element_section_count() != 2:
		return "Oblation unlock-section state did not survive round-trip."
	if not loaded_state.moon_upgrade_purchases.has("moon_b_1"):
		return "Moon upgrade purchases did not survive round-trip."
	if not loaded_state.oblation_claimed_recipe_ids.has("hydrogen_memory"):
		return "Oblation claims did not survive round-trip."
	return ""

func _test_progression_state() -> String:
	var state: GameState = TestSupportScript.build_state()
	if not state.can_unlock_next():
		return "Initial Hydrogen unlock should be affordable."
	if not state.unlock_next_element():
		return "Hydrogen unlock failed."
	if not state.is_element_unlocked("ele_H"):
		return "Hydrogen should be unlocked."
	if state.current_element_id != "ele_H":
		return "Current element should advance to Hydrogen."

	TestSupportScript.set_element_amount(state, "ele_He", 25.0)
	if not state.can_unlock_next():
		return "Helium unlock should be affordable after seeding Helium."
	if not state.unlock_next_element():
		return "Helium unlock failed."
	if state.current_element_id != "ele_He":
		return "Current element should advance to Helium."
	var next_unlock := state.get_next_unlock_element_state()
	if next_unlock == null or next_unlock.id != "ele_Li":
		return "Next unlock should advance to Lithium."
	if not state.select_adjacent_unlocked(-1) or state.current_element_id != "ele_H":
		return "Adjacent backward selection failed."
	if not state.select_adjacent_unlocked(1) or state.current_element_id != "ele_He":
		return "Adjacent forward selection failed."

	state.completed_milestones = ["planet_a_5"]
	state.next_milestone_id = "planet_b_5"
	if not state.confirm_oblation("hydrogen_memory", {"element_slot": "ele_H"}):
		return "Hydrogen Memory oblation should be claimable once milestone 1 is complete."
	if state.get_visible_element_section_count() != 2:
		return "Hydrogen Memory should reveal section 2."
	if state.get_max_unlockable_element_index() != 30:
		return "Visible unlock index should advance to 30."
	return ""

func _test_upgrade_aggregate() -> String:
	var state: GameState = TestSupportScript.build_state()
	var upgrades_system: UpgradesSystem = UpgradesSystemScript.new()
	TestSupportScript.unlock_elements(state, ["ele_H", "ele_He", "ele_Li", "ele_B", "ele_N", "ele_O", "ele_Na"])
	for resource_id in ["ele_H", "ele_He", "ele_Li", "ele_B", "ele_N", "ele_O", "ele_Na"]:
		TestSupportScript.set_element_amount(state, resource_id, 1000000.0)
	state.dust = DigitMaster.new(1000000.0)
	state.unlocked_era_index = 1
	state.refresh_progression_state()

	if not upgrades_system.purchase_upgrade(state, "particle_smasher"):
		return "Particle Smasher purchase failed."
	if state.get_upgrade_state("particle_smasher").current_level != 1:
		return "Particle Smasher level did not increment."
	if is_inf(upgrades_system.get_auto_smash_interval_seconds(state)):
		return "Particle Smasher should make auto smash interval finite."

	if not upgrades_system.purchase_upgrade(state, "critical_smasher_chance"):
		return "Critical Smasher Chance purchase failed."
	if upgrades_system.get_global_critical_smash_chance_percent(state) <= 0.0:
		return "Critical smash aggregate should increase after purchase."

	if not upgrades_system.purchase_upgrade(state, "smasher_bearings"):
		return "Smasher Bearings purchase failed."
	if upgrades_system.get_auto_smash_interval_multiplier(state) >= 1.0:
		return "Smasher Bearings should reduce the interval multiplier."

	if not upgrades_system.purchase_upgrade(state, "fission_1"):
		return "Fission purchase failed."
	if upgrades_system.get_fission_chance_percent(state) <= 0.0:
		return "Fission aggregate should increase after purchase."

	if not upgrades_system.purchase_upgrade(state, "critical_smasher_chance_2"):
		return "Tier 2 critical smasher purchase failed."
	var tier_two := state.get_upgrade_state("critical_smasher_chance_2")
	if tier_two.current_level != 1:
		return "Tier 2 upgrade level did not increment."
	if tier_two.secondary_current_cost.compare(tier_two.secondary_base_cost) <= 0:
		return "Tier 2 secondary cost did not advance."
	return ""

func _test_dust_recipe() -> String:
	var state: GameState = TestSupportScript.build_state()
	var upgrades_system: UpgradesSystem = UpgradesSystemScript.new()
	var dust_service: DustRecipeService = DustRecipeServiceScript.new()
	TestSupportScript.unlock_elements(state, ["ele_H", "ele_He", "ele_Li"])
	TestSupportScript.set_element_amount(state, "ele_H", 1000.0)
	TestSupportScript.set_element_amount(state, "ele_He", 800.0)
	TestSupportScript.set_element_amount(state, "ele_Li", 600.0)

	dust_service.cycle_selection("ele_H")
	dust_service.cycle_selection("ele_He")
	var base_preview := dust_service.get_preview(state, upgrades_system)
	if base_preview.is_zero():
		return "Dust preview should be positive after selecting unlocked elements."
	var cached_preview := dust_service.get_preview(state, upgrades_system)
	if not TestSupportScript.digit_equals(base_preview, cached_preview):
		return "Dust preview should be stable across cache hits."
	if dust_service.get_selected_element_ids(state, upgrades_system).size() != 2:
		return "Dust selection should include both chosen elements."

	state.set_upgrade_level("elemental_resonance", 2)
	dust_service.invalidate()
	var resonant_preview := dust_service.get_preview(state, upgrades_system)
	if resonant_preview.compare(base_preview) <= 0:
		return "Resonance upgrade should increase dust preview."

	dust_service.clear_selection()
	if not dust_service.get_preview(state, upgrades_system).is_zero():
		return "Dust preview should clear when no elements are selected."
	return ""

func _test_planet_production() -> String:
	var state: GameState = TestSupportScript.build_state()
	state.unlocked_era_index = 1
	state.planet_purchase_unlocks["planet_a"] = true
	state.planet_owned_flags["planet_a"] = true
	state.refresh_progression_state()

	var planet_a := state.get_planet_state("planet_a")
	if planet_a == null or not planet_a.unlocked:
		return "Planet A should be available in Planetary Era."

	state.dust = DigitMaster.new(100000.0)
	var worker_cost_before := state.get_current_planet_worker_cost()
	if not state.buy_current_planet_worker():
		return "Buying the first planet worker failed."
	if planet_a.workers.compare(DigitMaster.one()) != 0:
		return "Buying a worker should increment worker count."
	var worker_cost_after := state.get_current_planet_worker_cost()
	if worker_cost_after.compare(worker_cost_before) <= 0:
		return "Worker cost should increase after a purchase."

	planet_a.level = 1
	planet_a.xp = DigitMaster.zero()
	planet_a.xp_to_next_level = state._calculate_planet_xp_requirement(planet_a.level)
	planet_a.workers = DigitMaster.new(2000.0)
	planet_a.worker_allocation_to_xp = 1.0
	var changes: Dictionary = state.process_planet_production(1.0)
	if not bool(changes.get("current_planet_changed", false)):
		return "Planet XP allocation should report a current planet change."
	if planet_a.level <= 1:
		return "Planet XP allocation should level up Planet A."

	planet_a.workers = DigitMaster.new(1500.0)
	planet_a.worker_allocation_to_xp = 0.0
	var rp_before := state.research_points.clone()
	var progress_before := state.research_progress
	changes = state.process_planet_production(1.0)
	if not bool(changes.get("research_changed", false)):
		return "RP allocation should report research changes."
	if state.research_points.compare(rp_before) == 0 and is_equal_approx(state.research_progress, progress_before):
		return "RP allocation should advance research."
	return ""

func _test_element_system() -> String:
	var state: GameState = TestSupportScript.build_state()
	var upgrades_system: UpgradesSystem = UpgradesSystemScript.new()
	var element_system: ElementSystem = ElementSystemScript.new()
	TestSupportScript.unlock_elements(state, ["ele_H", "ele_He", "ele_Li"])
	TestSupportScript.set_element_amount(state, "ele_H", 1000.0)
	TestSupportScript.set_element_amount(state, "ele_He", 0.0)
	TestSupportScript.set_element_amount(state, "ele_Li", 0.0)
	state.current_element_id = "ele_H"

	var helium_before := state.get_resource_amount("ele_He")
	var manual_result := element_system.manual_smash(state, upgrades_system)
	if manual_result.is_empty():
		return "Manual smash should produce a result."
	if str(manual_result.get("produced_resource_id", "")) != "ele_He":
		return "Manual smash should produce Helium from Hydrogen."
	if state.get_resource_amount("ele_He").compare(helium_before) <= 0:
		return "Manual smash should increase Helium."
	if state.total_manual_smashes != 1:
		return "Manual smash count should increment."

	var lithium_before := state.get_resource_amount("ele_Li")
	var auto_result := element_system.resolve_auto_smash(state, upgrades_system, "ele_He")
	if auto_result.is_empty():
		return "Auto smash should produce a result."
	if state.get_resource_amount("ele_Li").compare(lithium_before) <= 0:
		return "Auto smash should increase Lithium."
	if state.total_auto_smashes != 1:
		return "Auto smash count should increment."
	return ""

func _test_fission_overflow_base_output() -> String:
	var state: GameState = TestSupportScript.build_state()
	var upgrades_system: UpgradesSystem = UpgradesSystemScript.new()
	var element_system: ElementSystem = ElementSystemScript.new()
	TestSupportScript.unlock_elements(state, ["ele_H", "ele_He", "ele_Li", "ele_B"])
	TestSupportScript.set_element_amount(state, "ele_Li", 1000.0)
	TestSupportScript.set_element_amount(state, "ele_H", 0.0)
	TestSupportScript.set_element_amount(state, "ele_He", 0.0)
	TestSupportScript.set_element_amount(state, "ele_B", 0.0)
	state.current_element_id = "ele_Li"

	upgrades_system._aggregate_cache_dirty = false
	upgrades_system._cached_fission_chance_percent = 200.0

	var result: Dictionary = element_system.manual_smash(state, upgrades_system)
	if not bool(result.get("was_fission", false)):
		return "Fission should be guaranteed at 200% chance."

	var resource_counts: Dictionary = result.get("resource_counts", {})
	if int(resource_counts.get("ele_B", 0)) != 1:
		return "Overflow above 100% should add one base product copy at 200% chance."
	if int(resource_counts.get("ele_H", 0)) != 1 or int(resource_counts.get("ele_He", 0)) != 1:
		return "Fission overflow should preserve the split pair."
	if state.get_resource_amount("ele_B").compare(DigitMaster.one()) != 0:
		return "Base overflow copy should be applied to resources."
	return ""

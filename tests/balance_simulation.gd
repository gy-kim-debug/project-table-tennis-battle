extends SceneTree

const Battle = preload("res://scripts/core/battle_manager.gd")
const Catalog = preload("res://scripts/core/pattern_catalog.gd")
const Judge = preload("res://scripts/core/timing_judge.gd")
const Rally = preload("res://scripts/core/rally_manager.gd")
const Balance = preload("res://resources/balance/battle.tres")
const Timing = preload("res://resources/balance/timing.tres")
const Pattern = preload("res://resources/patterns/basic_return.tres")

# Scripted input mixes estimate match length; they are not a human fun test.
const SKILLS: Dictionary = {
	"learning": [0.12, 0.43, 0.25, 0.20],
	"regular": [0.32, 0.45, 0.17, 0.06],
	"expert": [0.66, 0.29, 0.04, 0.01],
}
const SEEDS: int = 20

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var ability_delta: float = float(args[0]) if not args.is_empty() else 0.0
	for base_profile in Catalog.difficulties():
		var profile: Resource = base_profile.duplicate(true)
		profile.defense_ability += ability_delta
		for skill_name in SKILLS:
			var durations: Array[float] = []
			var player_wins: int = 0
			var timeouts: int = 0
			for case in range(SEEDS):
				var result: Dictionary = _simulate(profile, SKILLS[skill_name], 20261013 + case)
				durations.append(result["seconds"])
				player_wins += int(result["winner"] == 0)
				timeouts += int(result["winner"] < 0)
			durations.sort()
			var median: float = (durations[9] + durations[10]) / 2.0
			print("BALANCE %+d %s %s median=%.1fs p10=%.1fs p90=%.1fs player_wins=%d/%d timeouts=%d" % [roundi(ability_delta), profile.difficulty_id, skill_name, median, durations[1], durations[17], player_wins, SEEDS, timeouts])
	quit()

func _simulate(profile: Resource, chances: Array, seed_value: int) -> Dictionary:
	var battle: RefCounted = Battle.new(Balance, Timing, Pattern, null, profile, Catalog.all())
	battle.start(0)
	battle.enemy.rng.seed = seed_value
	var inputs: RandomNumberGenerator = RandomNumberGenerator.new()
	inputs.seed = seed_value * 13
	var now: int = 0
	for step in range(1000):
		if battle.state == Battle.State.BATTLE_END or now >= 300000000:
			break
		var model: RefCounted = battle.rally
		if model.state == Rally.State.RALLY_START or model.state == Rally.State.RALLY_RESULT:
			now = model.phase_start_us + roundi(Timing.serve_delay * 1000000.0)
			battle.advance(now)
			continue
		if model.state == Rally.State.PLAYER_TIMING:
			var roll: float = inputs.randf()
			var choice: int = 3
			var threshold: float = 0.0
			for index in range(4):
				threshold += float(chances[index])
				if roll < threshold:
					choice = index
					break
			var offsets: Array[int] = [0, 80000, 150000, 180001]
			now = model.target_us + offsets[choice]
			if choice == 3:
				battle.advance(now)
			else:
				assert(battle.swing(now) == choice)
				battle.advance(now)
			continue
		if model.state == Rally.State.PLAYER_RETURN:
			now = model.phase_start_us + roundi(model.pattern.return_seconds * 1000000.0)
			battle.advance(now)
			continue
		assert(false, "unexpected rally state")
	return {"seconds": float(now) / 1000000.0, "winner": battle.winner}

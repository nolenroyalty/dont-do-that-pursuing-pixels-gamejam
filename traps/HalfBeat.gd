extends GenericTrap

# Originally this fired on the and of four (thus HalfBeat) but I realized that firing on 1 was almost as good
# and much easier to reason about. It'd still be cool to add some kind of timing element to the game though.

onready var grid_tween = $GridTween
onready var half_beat_tween = $HalfBeatTween

const BLUE_TRANSPARENT = Color("#9630408c")
const RED_TRANSPARENT = Color("#968e3a47")

var penalized = {}
var tracking = {}
var firing = false

func pulse(_amount=null):
	.pulse(U.v(1.2, 1.2))
	grid_tween.pulse()

func tween_half(property, start, end, duration, delay):
	half_beat_tween.interpolate_property($Center, property, start, end, duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT, delay)

func pulse_center_red():
	var half_beat = U.beat_time / 2
	var full = U.v(1, 1)
	var double = U.v(2, 2)
	firing = true
	tween_half("scale", full, double, half_beat, 0)
	tween_half("modulate", BLUE_TRANSPARENT, RED_TRANSPARENT, half_beat, 0)
	tween_half("scale", double, full, half_beat, half_beat)
	tween_half("modulate", RED_TRANSPARENT, BLUE_TRANSPARENT, half_beat, half_beat)
	half_beat_tween.start()
	yield(half_beat_tween, "tween_all_completed")
	firing = false

func clear_penalties():
	penalized = {}

func entered(area):
	var moveable = moveable_of_area(area)
	if moveable == null: return
	tracking[moveable] = true

func exited(area):
	var moveable = moveable_of_area(area)
	if moveable == null: return
	tracking.erase(moveable)

func penalize_if_present():
	if not firing: return

	for moveable in tracking.keys():
		if moveable in penalized: continue
		
		if success_or_fail(moveable):
			penalized[moveable] = true
			moveable.damage()

func tick(beat):
	match beat:
		U.BEAT.NOOP:
			clear_penalties()
			pulse_center_red()
		U.BEAT.SHOW: pulse()
		U.BEAT.MOVE:
			pulse()

func _ready():
	pulse_tween.target = $Center
	grid_tween.target = $Grid
	var _ignore = $Area2D.connect("area_entered", self, "entered")
	_ignore = $Area2D.connect("area_exited", self, "exited")

func _process(_delta):
	if firing: penalize_if_present()
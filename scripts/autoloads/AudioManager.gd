## AudioManager - Handles all audio playback including per-peg tones

extends Node

# Per-peg tone definitions (from GDD aesthetic direction)
const PEG_TONES: Dictionary = {
	"stone": {"note": "C3", "wave": "sine", "duration": 0.3},
	"bone": {"note": "F2", "wave": "triangle", "duration": 0.25},
	"fungal": {"note": "G3", "wave": "sine", "duration": 0.4},
	"ember": {"note": "A4", "wave": "sawtooth", "duration": 0.35},
	"eye": {"note": "E4", "wave": "sine", "duration": 0.5},
	"heart": {"note": "C4", "wave": "triangle", "duration": 0.45},
	"oracle": {"note": "B4", "wave": "sine", "duration": 0.6},
	"void_rift": {"note": "C2", "wave": "sine", "duration": 0.8}
}

# State-based tone modifiers
const STATE_TONES: Dictionary = {
	"blessed": {"detune": 1200, "filter": "highpass"},
	"cursed": {"detune": -200, "filter": "lowpass"},
	"mutant": {"detune": 0, "filter": "bandpass"},
	"void_touched": {"detune": 800, "filter": "reverb"}
}

var master_volume: float = 0.8
var sfx_volume: float = 1.0
var music_volume: float = 0.6

# Placeholder audio stream players (would be replaced with actual audio)
var _stream_player: AudioStreamPlayer

func _ready() -> void:
	EventBus.peg_hit.connect(_on_peg_hit)
	_setup_audio_players()

func _setup_audio_players() -> void:
	# Create audio player nodes (in production, these would be SceneTree nodes)
	_stream_player = AudioStreamPlayer.new()
	add_child(_stream_player)

## Play the tone for a peg hit
func _on_peg_hit(peg: Node, ball: Node) -> void:
	var peg_type = peg.get("peg_type", "stone")
	var peg_state = peg.get("state", "neutral")

	var tone = PEG_TONES.get(peg_type, PEG_TONES["stone"])
	var state_mod = STATE_TONES.get(peg_state, {})

	_play_tone(tone, state_mod)

## Play a specific tone with state modification
func _play_tone(tone: Dictionary, state_mod: Dictionary) -> void:
	# In production, this would generate actual audio
	# For now, this is a placeholder for the audio system
	var frequency = _note_to_frequency(tone["note"])
	var detune = state_mod.get("detune", 0)

	print("Playing tone: %s at %d Hz (detune: %d)" % [tone["note"], frequency, detune])

## Convert note string to frequency
func _note_to_frequency(note: String) -> int:
	# Simplified note-to-frequency conversion
	# In production, would use proper music theory
	var notes = {
		"C2": 65, "D2": 73, "E2": 82, "F2": 87, "G2": 98, "A2": 110, "B2": 123,
		"C3": 131, "D3": 147, "E3": 165, "F3": 175, "G3": 196, "A3": 220, "B3": 247,
		"C4": 262, "D4": 294, "E4": 330, "F4": 349, "G4": 392, "A4": 440, "B4": 494,
		"C5": 523
	}
	return notes.get(note, 440)

## Play a UI sound effect
func play_ui_sound(sound_name: String) -> void:
	print("UI sound: %s" % sound_name)

## Play background ambience
func play_ambience(ambience_name: String) -> void:
	print("Ambience: %s" % ambience_name)

## Stop all audio
func stop_all() -> void:
	if _stream_player:
		_stream_player.stop()

## Set master volume
func set_master_volume(volume: float) -> void:
	master_volume = clampf(volume, 0.0, 1.0)

## Set SFX volume
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)

## Set music volume
func set_music_volume(volume: float) -> void:
	music_volume = clampf(volume, 0.0, 1.0)

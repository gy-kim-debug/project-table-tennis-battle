extends Resource

@export_range(1, 500) var perfect_ms: int = 50
@export_range(1, 500) var good_ms: int = 120
@export_range(1, 500) var bad_ms: int = 180
# Positive values compensate an input recorded late by the device.
@export_range(-200, 200) var input_offset_ms: int = 0
@export_range(0.1, 3.0) var serve_delay: float = 0.8

func is_valid() -> bool:
	return perfect_ms > 0 and perfect_ms <= good_ms and good_ms <= bad_ms

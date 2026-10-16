extends RefCounted
## Canonical, order-independent JSON used for fingerprints and comparisons.
## Godot parses every JSON number as float; whole floats are turned back into
## ints so `3` and `3.0` produce identical output.


static func normalize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			var f: float = value
			if is_finite(f) and f == floorf(f) and absf(f) < 9.0e15:
				return int(f)
			return f
		TYPE_DICTIONARY:
			var keys: Array = (value as Dictionary).keys()
			keys.sort_custom(func(a, b): return str(a) < str(b))
			var out := {}
			for key in keys:
				out[str(key)] = normalize(value[key])
			return out
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, \
				TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
			var out: Array = []
			for item in value:
				out.append(normalize(item))
			return out
		TYPE_STRING_NAME:
			return str(value)
	return value


static func stringify(value: Variant) -> String:
	return JSON.stringify(normalize(value), "", true)


static func sha256(value: Variant) -> String:
	return stringify(value).sha256_text()


## True when two values are equal after normalization (e.g. 4 vs 4.0).
static func equal(a: Variant, b: Variant) -> bool:
	return stringify(a) == stringify(b)

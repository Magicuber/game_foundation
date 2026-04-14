# DigitMaster - Large Number System

## Overview

`DigitMaster` is a custom number class for Idle Universe that handles arbitrarily large values beyond standard floating-point limits. It uses scientific notation internally to represent numbers up to effectively infinite magnitude.

**File:** [`src/core/DigitMaster.gd`](../src/core/DigitMaster.gd)

## Why Custom Numbers?

Standard Godot/GDScript number types have limitations:
- `int`: Limited to 64-bit (~9e18)
- `float`: Loses precision after ~1e15

Idle Universe requires representing numbers like:
- 1.5 × 10^308 (largest float)
- 1.0 × 10^1000+ (endgame values)
- Infinite resources (Protons)

## Internal Representation

```gdscript
class_name DigitMaster

var mantissa: float   # Significand (1.0 ≤ |mantissa| < 10.0)
var exponent: int     # Power of 10
var is_infinite: bool # Special infinity flag

# Number = mantissa × 10^exponent
# Example: 1.5 × 10^308
```

### Normalization

Numbers are automatically normalized to maintain precision:

```gdscript
func normalize() -> void:
    if abs(mantissa) >= 10.0:
        # Shift decimal left, increase exponent
        var extra := floor(log(abs(mantissa)) / log(10.0))
        exponent += int(extra)
        mantissa /= pow(10.0, extra)
    elif abs(mantissa) < 1.0 and mantissa != 0.0:
        # Shift decimal right, decrease exponent
        var extra := floor(log(abs(mantissa)) / log(10.0))
        exponent += int(extra)
        mantissa /= pow(10.0, extra)
```

**Examples of normalization:**
- Input: 1500.0 → Output: mantissa=1.5, exponent=3
- Input: 0.005 → Output: mantissa=5.0, exponent=-3
- Input: 15.0 × 10^10 → Output: mantissa=1.5, exponent=11

## Factory Methods

```gdscript
# Create zero
var zero := DigitMaster.zero()  # mantissa=0, exponent=0

# Create one
var one := DigitMaster.one()    # mantissa=1.0, exponent=0

# Create infinity
var infinite := DigitMaster.infinity()  # is_infinite=true

# Parse from various types
var from_number := DigitMaster.new(1500.0)          # Direct value
var from_exp := DigitMaster.new(1.5, 308)            # mantissa + exponent
var from_dict := DigitMaster.from_variant({"mantissa": 1.5, "exponent": 308})
var from_string := DigitMaster.from_variant("1500")
var from_int := DigitMaster.from_variant(1500)
```

## Operations

### Addition

```gdscript
func add(other: DigitMaster) -> DigitMaster:
    if is_infinite or other.is_infinite:
        return DigitMaster.infinity()
    if is_zero():
        return other.clone()
    if other.is_zero():
        return clone()
    
    # Align exponents first
    if exponent == other.exponent:
        return DigitMaster.new(mantissa + other.mantissa, exponent)
    if exponent > other.exponent:
        var diff := exponent - other.exponent
        var other_scaled := other.mantissa / pow(10.0, diff)
        return DigitMaster.new(mantissa + other_scaled, exponent)
    # ... reverse case
```

**Algorithm:**
1. If different exponents, scale smaller number to match larger exponent
2. Add mantissas
3. Normalize result

**Example:** 1.5e10 + 2.0e8
1. Convert: 1.5e10 + 0.02e10
2. Add: 1.52e10
3. Result: mantissa=1.52, exponent=10

### Subtraction

```gdscript
func subtract(other: DigitMaster) -> DigitMaster:
    # Similar to addition, but:
    # - Returns zero if result would be negative
    # - Clamps to zero (no negative numbers in game)
```

### Scalar Multiplication

```gdscript
func multiply_scalar(scalar: float) -> DigitMaster:
    if scalar == 0.0 or is_zero():
        return DigitMaster.zero()
    if is_infinite:
        return DigitMaster.infinity()
    return DigitMaster.new(mantissa * scalar, exponent)
    # Automatic normalization handles mantissa overflow
```

**Note:** Only scalar multiplication (float) is supported, not `DigitMaster × DigitMaster`.

### Power

```gdscript
func power(exp: float) -> DigitMaster:
    # (m × 10^e)^p = m^p × 10^(e×p)
    result.mantissa = pow(mantissa, exp)
    result.exponent = int(exponent * exp)
    result.normalize()
```

**Use case:** Calculating dust from oblations with fractional exponents:
```gdscript
var base_amount := total_elements.power(0.9)  # Quantity^0.9
```

### Comparison

```gdscript
func compare(other: DigitMaster) -> int:
    # Returns: -1 (less), 0 (equal), 1 (greater)
    
    if is_infinite and other.is_infinite:
        return 0
    if is_infinite:
        return 1
    if other.is_infinite:
        return -1
    
    # Compare exponents first (dominant factor)
    if exponent != other.exponent:
        return 1 if exponent > other.exponent else -1
    
    # Same exponent: compare mantissas
    if mantissa < other.mantissa:
        return -1
    if mantissa > other.mantissa:
        return 1
    return 0
```

## Conversion

### To Float

```gdscript
func to_float() -> float:
    if is_infinite:
        return INF
    if is_zero():
        return 0.0
    return mantissa * pow(10.0, exponent)
    # Risk: overflow for large exponents!
```

**Warning:** Converting to float loses precision and may overflow. Use only when necessary (e.g., for UI progress bars).

### String Formatting

#### Scientific Notation

```gdscript
func big_to_string() -> String:
    if is_infinite:
        return "Infinity"
    if is_zero():
        return "0"
    return "%.2fe%d" % [mantissa, exponent]
    # Example: "1.50e308"
```

#### Short Notation (with suffixes)

```gdscript
func big_to_short_string() -> String:
    if is_infinite:
        return "Infinity"
    if is_zero():
        return "0"
    
    # Small numbers: show as integer
    if exponent < 5:
        return "%d" % int(round(to_float()))
    
    # Large numbers: use suffixes
    var suffixes := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
    var suffix_index := int(floor(exponent / 3.0))
    
    if suffix_index >= suffixes.size():
        return big_to_string()  # Fallback to scientific
    
    # Adjust mantissa for display
    var display_val := mantissa * pow(10.0, exponent % 3)
    return "%.1f%s" % [display_val, suffixes[suffix_index]]
```

**Output examples:**
| Value | big_to_string() | big_to_short_string() |
|-------|-----------------|----------------------|
| 1500 | 1.50e3 | 1500 |
| 1500000 | 1.50e6 | 1.5M |
| 1.5e18 | 1.50e18 | 1.5Qi |
| 1.5e308 | 1.50e308 | 1.50e308 (overflow) |

### Suffix Table

| Suffix | Power | Full Name |
|--------|-------|-----------|
| (none) | 10^0 | - |
| K | 10^3 | Thousand |
| M | 10^6 | Million |
| B | 10^9 | Billion |
| T | 10^12 | Trillion |
| Qa | 10^15 | Quadrillion |
| Qi | 10^18 | Quintillion |
| Sx | 10^21 | Sextillion |
| Sp | 10^24 | Septillion |
| Oc | 10^27 | Octillion |
| No | 10^30 | Nonillion |
| Dc | 10^33 | Decillion |

## Serialization

For save/load compatibility:

```gdscript
func to_save_data() -> Dictionary:
    return {
        "mantissa": mantissa,
        "exponent": exponent,
        "is_infinite": is_infinite
    }

static func from_variant(value: Variant) -> DigitMaster:
    match typeof(value):
        TYPE_DICTIONARY:
            var dict: Dictionary = value
            if bool(dict.get("is_infinite", false)):
                return DigitMaster.infinity()
            return DigitMaster.new(
                float(dict.get("mantissa", 0.0)),
                int(dict.get("exponent", 0))
            )
        TYPE_INT, TYPE_FLOAT:
            return DigitMaster.new(float(value))
        TYPE_STRING:
            if str(value).strip_edges().to_lower() == "infinity":
                return DigitMaster.infinity()
            if str(value).is_valid_float():
                return DigitMaster.new(str(value).to_float())
            return DigitMaster.zero()
```

## Edge Cases

| Input | Behavior |
|-------|----------|
| Negative numbers | Supported (rare in game) |
| Zero | Special case: mantissa=0, exponent=0 |
| Infinity | Special flag, not actual math |
| Very large exponents | Maintains mantissa precision up to ~1e308 |
| Division | **Not implemented** - use multiply_scalar(1.0/x) |
| Negative exponents | Supported (0.001 = 1.0e-3) |

## Usage in Game State

All large game values use `DigitMaster`:

```gdscript
# GameState core properties
var dust: DigitMaster          # Primary currency
var research_points: DigitMaster  # For moon upgrades
var global_multiplier: DigitMaster  # Production bonus

# Element amounts
var amount: DigitMaster  # In ElementState

# Planet XP
var xp: DigitMaster
var xp_to_next_level: DigitMaster

# Worker counts
var workers: DigitMaster
```

## Comparison with Standard Float

| Operation | Float | DigitMaster |
|-----------|-------|-------------|
| 1e20 + 1e2 | Precision loss | Exact 1e20 |
| Storage | 8 bytes | ~16 bytes + object overhead |
| Speed | Native hardware | GDScript operations |
| Range | ~1e308 | Effectively unlimited |

## Best Practices

1. **Always clone** before modifying:
   ```gdscript
   var new_amount = current_amount.clone()
   new_amount = new_amount.add(additional_amount)
   ```

2. **Use short string** for UI display

3. **Compare instead of convert**:
   ```gdscript
   # Good
   if amount.compare(cost) >= 0:
       
   # Bad - precision loss
   if amount.to_float() >= cost.to_float():
   ```

4. **Check is_zero()** before operations that might fail

5. **Use scalar multiplication** for game multipliers:
   ```gdscript
   var bonus := base_amount.multiply_scalar(1.25)  # +25%
   ```

## Related Documentation

- [Save System](./save_system.md) - Serialization details
- [Game Mechanics](./game_mechanics.md) - Usage in calculations
- [Data Format](./data_format.md) - JSON representation
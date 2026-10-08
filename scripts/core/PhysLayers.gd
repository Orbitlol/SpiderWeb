extends RefCounted
class_name PhysLayers

## Collision layers. Bit 0 is Godot physics layer 1.
const WORLD := 1 << 0
const PLAYER := 1 << 1
const VEHICLE := 1 << 2
const CHARACTER := 1 << 3
const TRIGGER := 1 << 4
const PROJECTILE := 1 << 5

const ANCHOR_MASK := WORLD | VEHICLE | CHARACTER
const PLAYER_MASK_GROUND := WORLD | VEHICLE | CHARACTER
const PLAYER_MASK_AIR := WORLD | VEHICLE

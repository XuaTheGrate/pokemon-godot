class_name Evolution
extends Resource

@export var species: String
@export var type: String
@export var extra: Variant

static func create(species_: String, type_: String, extra_: Variant) -> Evolution:
	var r := Evolution.new()
	r.species = species_
	r.type = type_
	r.extra = extra_
	return r

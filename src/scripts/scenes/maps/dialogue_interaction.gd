extends InteractionComponent

@export var dialogue_resource: DialogueResource
@export var dialogue_cue: String = ""

func interact() -> void:
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_cue)
	await DialogueManager.dialogue_ended

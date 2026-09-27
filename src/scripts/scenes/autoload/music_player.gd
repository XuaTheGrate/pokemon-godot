extends AudioStreamPlayer

func play_stream(stream_: AudioStream) -> void:
	if stream_ != stream:
		stop()
		stream = stream_
		play()

func fade_out_music(time: float = 0.5) -> void:
	if not playing: return
	
	var t := create_tween()
	var old_vol := volume_linear
	t.tween_property(self, ^"volume_linear", 0.0, time)
	t.tween_callback(stop)
	t.tween_property(self, ^"volume_linear", old_vol, 0.0)

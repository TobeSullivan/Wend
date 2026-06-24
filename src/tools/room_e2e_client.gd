extends Node


func _ready() -> void:
	var host := OS.get_environment("MBTD_SERVER")
	if host == "":
		host = "5.78.110.182"
	var mid := OS.get_environment("MBTD_MATCH")
	var nm := OS.get_environment("MBTD_NAME")
	var exp_env := OS.get_environment("MBTD_EXPECTED")
	var expected := int(exp_env) if exp_env != "" else 2
	print("[client %s] join %s room=%s expected=%d" % [nm, host, mid, expected])

	var err := SceneManager.net_join(host)
	if err != OK:
		print("[client %s] net_join error %d  RESULT FAIL" % [nm, err]); get_tree().quit(2); return
	var t = SceneManager.transport
	t.connection_succeeded.connect(func():
		print("[client %s] connected → JOIN_ROOM" % nm)
		t.send_to_authority({"t": NetProtocol.JOIN_ROOM, "match_id": mid, "name": nm, "expected": expected, "tier": 1}))
	t.connection_failed.connect(func():
		print("[client %s] connection failed  RESULT FAIL" % nm); get_tree().quit(3))
	t.server_closed.connect(func():
		print("[client %s] server closed  RESULT FAIL" % nm); get_tree().quit(4))
	t.received.connect(func(_from, msg):
		if String(msg.get("t", "")) == NetProtocol.START_MATCH:
			print("[client %s] GOT START_MATCH seat=%d count=%d seed=%d tier=%d  RESULT OK" % [
				nm, int(msg["seat"]), int(msg["count"]), int(msg["seed"]), int(msg["tier"])])
			get_tree().quit(0))

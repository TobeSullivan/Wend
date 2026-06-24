extends Node

func _ready() -> void:
	_route.call_deferred()

func _route() -> void:
	if "--server" in OS.get_cmdline_user_args():
		SceneManager.start_dedicated_server()
		return
	if NakamaService.is_configured():
		NakamaService.connect_backend()
	if SaveData.is_first_launch():
		SaveData.mark_first_launch_done()
		if SceneManager.has_campaign_mission(1):
			SceneManager.start_campaign_mission(1)
			return
	SceneManager.goto_home()

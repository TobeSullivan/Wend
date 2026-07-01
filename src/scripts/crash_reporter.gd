extends Node

const LOG_DIR := "user://logs"
const ACTIVE_LOG := "godot.log"
const MAX_SCAN_BYTES := 512 * 1024
const MAX_UPLOAD_BYTES := 48 * 1024
const UPLOADED_KEY := "crash_logs_uploaded"
const UPLOADED_HISTORY := 20
const ERROR_MARKERS := [
	"ERROR:", "SCRIPT ERROR", "USER ERROR", "USER SCRIPT ERROR",
	"Dumping the backtrace", "handle_crash", "Program crashed", "Lambda capture",
]

var _pending: Array = []

func _ready() -> void:
	if "--server" in OS.get_cmdline_user_args():
		return
	_scan.call_deferred()

func _scan() -> void:
	_pending = _collect_error_logs()
	if _pending.is_empty():
		return
	if NakamaService.has_session():
		_flush()
	elif NakamaService.is_configured():
		NakamaService.session_ready.connect(_on_session_ready)

func _on_session_ready(_session) -> void:
	_flush()

func _flush() -> void:
	for entry in _pending:
		var ok: bool = await NakamaService.report_client_log_async(_build_payload(entry))
		if ok:
			_mark_uploaded(entry["name"])
	_pending.clear()

func _collect_error_logs() -> Array:
	var out: Array = []
	var dir := DirAccess.open(LOG_DIR)
	if dir == null:
		return out
	var uploaded: Array = SaveData.data.get(UPLOADED_KEY, [])
	var names: Array = []
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.ends_with(".log") and f != ACTIVE_LOG and not (f in uploaded):
			names.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	names.sort_custom(_newer_first)
	for name in names:
		var path := "%s/%s" % [LOG_DIR, name]
		var text := _read_log(path)
		var errs := _count_errors(text)
		if errs > 0:
			out.append({"name": name, "text": _tail(text, MAX_UPLOAD_BYTES), "errors": errs})
	return out

func _newer_first(a: String, b: String) -> bool:
	return FileAccess.get_modified_time("%s/%s" % [LOG_DIR, a]) > FileAccess.get_modified_time("%s/%s" % [LOG_DIR, b])

func _read_log(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var size := f.get_length()
	if size > MAX_SCAN_BYTES:
		f.seek(size - MAX_SCAN_BYTES)
	var text := f.get_as_text()
	f.close()
	return text

func _count_errors(text: String) -> int:
	var n := 0
	for marker in ERROR_MARKERS:
		n += text.count(marker)
	return n

func _tail(text: String, max_bytes: int) -> String:
	if text.length() <= max_bytes:
		return text
	return text.substr(text.length() - max_bytes)

func _build_payload(entry: Dictionary) -> Dictionary:
	var gv: Dictionary = Engine.get_version_info()
	return {
		"log": entry["text"],
		"tag": String(entry["name"]).get_basename(),
		"platform": OS.get_name(),
		"version": String(ProjectSettings.get_setting("application/config/version", "")),
		"godot": String(gv.get("string", "")),
		"errors": int(entry["errors"]),
	}

func _mark_uploaded(name: String) -> void:
	var uploaded: Array = SaveData.data.get(UPLOADED_KEY, [])
	if name in uploaded:
		return
	uploaded.append(name)
	while uploaded.size() > UPLOADED_HISTORY:
		uploaded.pop_front()
	SaveData.data[UPLOADED_KEY] = uploaded
	SaveData.save()

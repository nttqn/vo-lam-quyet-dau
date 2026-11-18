@tool
extends EditorPlugin
## Adds the VLGoogleAuth AAR (built in CI into bin/) and its libraries to
## Android gradle exports.

var _exp: VLGoogleAuthExport

func _enter_tree() -> void:
	_exp = VLGoogleAuthExport.new()
	add_export_plugin(_exp)

func _exit_tree() -> void:
	remove_export_plugin(_exp)
	_exp = null

class VLGoogleAuthExport extends EditorExportPlugin:
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["VLGoogleAuth/bin/VLGoogleAuth-release.aar"])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([
			"androidx.credentials:credentials:1.5.0",
			"androidx.credentials:credentials-play-services-auth:1.5.0",
			"com.google.android.libraries.identity.googleid:googleid:1.1.1",
		])

	func _get_name() -> String:
		return "VLGoogleAuth"

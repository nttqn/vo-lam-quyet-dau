extends Node
## Ads (autoload "Ads"): AdMob rewarded ads through the Poing Studios plugin.
## Android only. Flow at start: UMP consent (EEA/UK) -> MobileAds.initialize ->
## preload one rewarded ad. Elsewhere (desktop tests) show_rewarded grants the
## reward straight away in debug builds so the reward flows can be exercised.
##
## Unit ids are Google's test ids until the real AdMob app exists
## (project.godot [admob] general/android/app_id holds the app id).

signal ready_changed

const REWARDED_UNIT := "ca-app-pub-3940256099942544/5224354917"   # TODO real unit id

var _android := OS.get_name() == "Android"
var _started := false
var _sdk_ready := false   # next-gen SDK: nothing may load before initialize completes
var _ad: RewardedAd
var _loading := false
var _retry := 0.0
var _load_cb := RewardedAdLoadCallback.new()
var _content_cb := FullScreenContentCallback.new()
var _reward_cb := OnUserEarnedRewardListener.new()
var _on_reward: Callable
var _rewarded := false
var _on_close: Callable

func _ready() -> void:
	if not _android:
		return
	_load_cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		_loading = false
		_ad = ad
		_ad.full_screen_content_callback = _content_cb
		ready_changed.emit()
	_load_cb.on_ad_failed_to_load = func(err: LoadAdError) -> void:
		_loading = false
		_retry = 30.0
		print("Ads: load failed ", err.message)
	_reward_cb.on_user_earned_reward = func(_item: RewardedItem) -> void:
		_rewarded = true
	_content_cb.on_ad_dismissed_full_screen_content = func() -> void:
		_finish()
	_content_cb.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
		print("Ads: show failed ", err.message)
		_finish()
	_consent()

func _process(delta: float) -> void:
	if _retry > 0.0:
		_retry -= delta
		if _retry <= 0.0:
			_load()

# ------------------------------------------------------------- public
## True when show_rewarded can play an ad right now.
func is_ready() -> bool:
	if not _android:
		return OS.is_debug_build()
	return _ad != null

## Plays a rewarded ad. on_reward runs (once) only if the player watched it to
## the end; on_close always runs afterwards (ad closed, failed, or none).
func show_rewarded(on_reward: Callable, on_close := Callable()) -> bool:
	if not _android:
		if OS.is_debug_build():
			on_reward.call()
			if on_close.is_valid():
				on_close.call()
			return true
		return false
	if _ad == null:
		_load()
		return false
	_on_reward = on_reward
	_on_close = on_close
	_rewarded = false
	Game.music_pause(true)
	_ad.show(_reward_cb)
	return true

func privacy_options_required() -> bool:
	if not _android:
		return false
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() \
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

func show_privacy_options() -> void:
	if _android:
		UserMessagingPlatform.show_privacy_options_form(_ignore)

# ------------------------------------------------------------- internals
func _consent() -> void:
	UserMessagingPlatform.consent_information.update(ConsentRequestParameters.new(), _consent_updated, _consent_failed)

func _consent_updated() -> void:
	if UserMessagingPlatform.consent_information.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(_form_loaded, _consent_failed)
	else:
		_start()

func _form_loaded(form: ConsentForm) -> void:
	if UserMessagingPlatform.consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		form.show(_consent_failed)   # dismissed (with or without error): go on
	else:
		_start()

func _consent_failed(_err = null) -> void:
	_start()

func _ignore(_err = null) -> void:
	pass

func _start() -> void:
	if _started:
		return
	_started = true
	var l := OnInitializationCompleteListener.new()
	l.on_initialization_complete = func(_s) -> void:
		_sdk_ready = true
		_load()
	MobileAds.initialize(l)
	_load()

func _load() -> void:
	if not _sdk_ready or _loading or _ad != null:
		return
	_loading = true
	RewardedAdLoader.new().load(REWARDED_UNIT, AdRequest.new(), _load_cb)

func _finish() -> void:
	Game.music_pause(false)
	if _ad:
		_ad.destroy()
		_ad = null
	ready_changed.emit()
	var r := _on_reward
	var c := _on_close
	_on_reward = Callable()
	_on_close = Callable()
	if _rewarded and r.is_valid():
		r.call()
	_rewarded = false
	if c.is_valid():
		c.call()
	_load()

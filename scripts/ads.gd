extends Node
## Ads (autoload "Ads"): AdMob rewarded ads through the Poing Studios plugin.
## Android and iOS. Flow at start: UMP consent (EEA/UK) -> MobileAds.initialize ->
## preload one rewarded ad. Elsewhere (desktop tests) show_rewarded grants the
## reward straight away in debug builds so the reward flows can be exercised.
##
## Also an interstitial (on leaving a result screen for a menu, see
## maybe_interstitial) and an App Open ad (coming back after APP_OPEN_AWAY_S),
## both skipped for new heroes and kept apart by INTER_GAP_S.
## (project.godot [admob] general/android/app_id and general/ios/app_id hold the app ids.)

signal ready_changed

# Ad units per platform (iOS app id: project.godot general/ios/app_id).
var REWARDED_UNIT := "ca-app-pub-9078637596840810/6134617670" if OS.get_name() == "iOS" else "ca-app-pub-9078637596840810/7086713053"
var INTER_UNIT := "ca-app-pub-9078637596840810/3700026026" if OS.get_name() == "iOS" else "ca-app-pub-9078637596840810/2854844066"
var APP_OPEN_UNIT := "ca-app-pub-9078637596840810/4385200540" if OS.get_name() == "iOS" else "ca-app-pub-9078637596840810/5773631387"
const INTER_GAP_S := 240.0        # no interstitial within 4 min of any full-screen ad or the start
const APP_OPEN_AWAY_S := 1800.0   # App Open only after 30 min away
const NO_ADS_BELOW_LEVEL := 10    # new heroes see only the rewarded ads they ask for

var _inter: InterstitialAd
var _inter_loading := false
var _open: AppOpenAd
var _open_loading := false
var _last_full := 0.0             # ticks (s) of the last full-screen ad; app start counts
var _paused_at := -1.0
var _full_showing := false
var _plain_cb := FullScreenContentCallback.new()

var _ads_on := OS.get_name() in ["Android", "iOS"]   # mobile builds with the AdMob plugin
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
	if not _ads_on:
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
	_plain_cb.on_ad_dismissed_full_screen_content = func() -> void:
		_plain_done()
	_plain_cb.on_ad_failed_to_show_full_screen_content = func(err: AdError) -> void:
		print("Ads: show failed ", err.message)
		_plain_done()
	_last_full = _now()
	_consent()

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

# ------------------------------------------------------- interstitial / app open
func _ads_allowed() -> bool:
	return _ads_on and not Iap.no_ads() and _sdk_ready and not _full_showing \
		and int(Game.hero.get("level", 1)) >= NO_ADS_BELOW_LEVEL

## Called when a result screen is left for a menu. Shows an interstitial
## only if one is loaded and INTER_GAP_S has passed since the last full-screen ad.
func maybe_interstitial() -> void:
	if not _ads_allowed():
		return
	if _inter == null:
		_load_inter()
		return
	if _now() - _last_full < INTER_GAP_S:
		return
	var ad := _inter
	_inter = null
	ad.full_screen_content_callback = _plain_cb
	_full_showing = true
	Game.music_pause(true)
	ad.show()

func _notification(what: int) -> void:
	if not _ads_on:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		if not _full_showing:
			_paused_at = _now()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		var away := _now() - _paused_at if _paused_at >= 0.0 else 0.0
		_paused_at = -1.0
		if away >= APP_OPEN_AWAY_S:
			_maybe_app_open.call_deferred()

func _maybe_app_open() -> void:
	if not _ads_allowed() or Game._current is FightScene:
		return
	if _open == null:
		_load_open()
		return
	var ad := _open
	_open = null
	ad.full_screen_content_callback = _plain_cb
	_full_showing = true
	Game.music_pause(true)
	ad.show()

func _plain_done() -> void:
	_full_showing = false
	_last_full = _now()
	Game.music_pause(false)
	_load_inter()
	_load_open()

func _load_inter() -> void:
	if not _sdk_ready or _inter_loading or _inter != null:
		return
	_inter_loading = true
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_inter_loading = false
		_inter = ad
	cb.on_ad_failed_to_load = func(err: LoadAdError) -> void:
		_inter_loading = false
		print("Ads: interstitial load failed ", err.message)
	InterstitialAdLoader.new().load(INTER_UNIT, AdRequest.new(), cb)

func _load_open() -> void:
	if not _sdk_ready or _open_loading or _open != null:
		return
	_open_loading = true
	var cb := AppOpenAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: AppOpenAd) -> void:
		_open_loading = false
		_open = ad
	cb.on_ad_failed_to_load = func(err: LoadAdError) -> void:
		_open_loading = false
		print("Ads: app open load failed ", err.message)
	AppOpenAdLoader.new().load(APP_OPEN_UNIT, AdRequest.new(), cb)

func _process(delta: float) -> void:
	if _retry > 0.0:
		_retry -= delta
		if _retry <= 0.0:
			_load()

# ------------------------------------------------------------- public
## True when show_rewarded can play an ad right now.
func is_ready() -> bool:
	if Iap.no_ads():
		return true
	if not _ads_on:
		return OS.is_debug_build()
	return _ad != null

## Plays a rewarded ad. on_reward runs (once) only if the player watched it to
## the end; on_close always runs afterwards (ad closed, failed, or none).
func show_rewarded(on_reward: Callable, on_close := Callable()) -> bool:
	# Bỏ Quảng Cáo: the reward without the ad
	if Iap.no_ads():
		on_reward.call()
		if on_close.is_valid():
			on_close.call()
		return true
	if not _ads_on:
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
	_full_showing = true
	Game.music_pause(true)
	_ad.show(_reward_cb)
	return true

func privacy_options_required() -> bool:
	if not _ads_on:
		return false
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() \
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

func show_privacy_options() -> void:
	if _ads_on:
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
		_load_inter()
		_load_open()
	MobileAds.initialize(l)
	_load()

func _load() -> void:
	if not _sdk_ready or _loading or _ad != null:
		return
	_loading = true
	RewardedAdLoader.new().load(REWARDED_UNIT, AdRequest.new(), _load_cb)

func _finish() -> void:
	_full_showing = false
	_last_full = _now()
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

package com.trungsmail.vlauth;

import android.app.Activity;
import android.os.Bundle;

import androidx.annotation.NonNull;

import com.google.firebase.analytics.FirebaseAnalytics;

import org.godotengine.godot.Dictionary;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/**
 * Firebase Analytics for Võ Lâm Quyết Đấu. Firebase itself starts at launch
 * from res/values/firebase.xml (FirebaseInitProvider), so sessions, active
 * users and first_open are collected with no call from the game. The game
 * adds its own events with logEvent and names screens with screen().
 */
public class VLAnalytics extends GodotPlugin {
    private FirebaseAnalytics fa;

    public VLAnalytics(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "VLAnalytics";
    }

    private FirebaseAnalytics fa() {
        if (fa == null) {
            Activity act = getActivity();
            if (act != null) {
                try {
                    fa = FirebaseAnalytics.getInstance(act.getApplicationContext());
                } catch (Throwable t) {
                    fa = null;
                }
            }
        }
        return fa;
    }

    /** Event with string / int / float / bool params (others are sent as text). */
    @UsedByGodot
    public void logEvent(String name, Dictionary params) {
        FirebaseAnalytics a = fa();
        if (a == null) return;
        Bundle b = new Bundle();
        if (params != null) {
            for (String k : params.get_keys()) {
                Object v = params.get(k);
                if (v instanceof Integer) b.putLong(k, (Integer) v);
                else if (v instanceof Long) b.putLong(k, (Long) v);
                else if (v instanceof Float) b.putDouble(k, (Float) v);
                else if (v instanceof Double) b.putDouble(k, (Double) v);
                else if (v instanceof Boolean) b.putLong(k, ((Boolean) v) ? 1 : 0);
                else if (v != null) b.putString(k, String.valueOf(v));
            }
        }
        a.logEvent(name, b);
    }

    /** screen_view under a screen name (the game has a single Activity). */
    @UsedByGodot
    public void screen(String name) {
        FirebaseAnalytics a = fa();
        if (a == null) return;
        Bundle b = new Bundle();
        b.putString(FirebaseAnalytics.Param.SCREEN_NAME, name);
        b.putString(FirebaseAnalytics.Param.SCREEN_CLASS, name);
        a.logEvent(FirebaseAnalytics.Event.SCREEN_VIEW, b);
    }

    @UsedByGodot
    public void setUserProperty(String name, String value) {
        FirebaseAnalytics a = fa();
        if (a != null) a.setUserProperty(name, value);
    }
}

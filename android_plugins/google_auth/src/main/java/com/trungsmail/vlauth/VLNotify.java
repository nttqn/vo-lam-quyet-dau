package com.trungsmail.vlauth;

import android.Manifest;
import android.app.Activity;
import android.app.AlarmManager;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.annotation.NonNull;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/**
 * Local reminders for Võ Lâm Quyết Đấu (1.3.0). The game schedules a few
 * notifications whenever it goes to the background and cancels them when it
 * comes back. Alarms are inexact (no exact-alarm permission); NotifyReceiver
 * posts them. The ids in use are kept in prefs so cancelAll() finds them.
 */
public class VLNotify extends GodotPlugin {
    static final String CHANNEL = "volam_remind";
    static final String PREFS = "vl_notify";

    public VLNotify(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "VLNotify";
    }

    private Context ctx() {
        Activity a = getActivity();
        return a != null ? a.getApplicationContext() : null;
    }

    static void ensureChannel(Context c) {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationManager nm = (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null && nm.getNotificationChannel(CHANNEL) == null) {
                NotificationChannel ch = new NotificationChannel(CHANNEL, "Nhắc nhở giang hồ", NotificationManager.IMPORTANCE_DEFAULT);
                ch.setDescription("Boss Thế Giới, điểm danh và trận đấu đang chờ");
                nm.createNotificationChannel(ch);
            }
        }
    }

    private static PendingIntent pending(Context c, int id, String title, String body) {
        Intent i = new Intent(c, NotifyReceiver.class);
        i.putExtra("id", id);
        i.putExtra("title", title);
        i.putExtra("body", body);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= 23) flags |= PendingIntent.FLAG_IMMUTABLE;
        return PendingIntent.getBroadcast(c, id, i, flags);
    }

    /** True when the app may post notifications (Android 13+ asks at runtime). */
    @UsedByGodot
    public boolean allowed() {
        Context c = ctx();
        if (c == null) return false;
        if (Build.VERSION.SDK_INT >= 33
                && c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            return false;
        }
        NotificationManager nm = (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
        return nm == null || Build.VERSION.SDK_INT < 24 || nm.areNotificationsEnabled();
    }

    /** Shows the system permission prompt on Android 13+ (no-op below). */
    @UsedByGodot
    public void requestPermission() {
        Activity a = getActivity();
        if (a == null || Build.VERSION.SDK_INT < 33) return;
        if (a.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) return;
        a.runOnUiThread(() -> a.requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 7301));
    }

    /** One reminder `delaySec` seconds from now; the same id replaces the old one. */
    @UsedByGodot
    public void schedule(int id, int delaySec, String title, String body) {
        Context c = ctx();
        if (c == null) return;
        ensureChannel(c);
        AlarmManager am = (AlarmManager) c.getSystemService(Context.ALARM_SERVICE);
        if (am == null) return;
        long at = System.currentTimeMillis() + Math.max(60, delaySec) * 1000L;
        try {
            am.set(AlarmManager.RTC_WAKEUP, at, pending(c, id, title, body));
        } catch (Throwable t) {
            return;
        }
        SharedPreferences p = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        String ids = p.getString("ids", "");
        String key = "," + id + ",";
        if (!("," + ids + ",").contains(key)) {
            p.edit().putString("ids", ids.isEmpty() ? String.valueOf(id) : ids + "," + id).apply();
        }
    }

    /** Cancels every scheduled reminder and clears the shown ones. */
    @UsedByGodot
    public void cancelAll() {
        Context c = ctx();
        if (c == null) return;
        AlarmManager am = (AlarmManager) c.getSystemService(Context.ALARM_SERVICE);
        SharedPreferences p = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        String ids = p.getString("ids", "");
        if (am != null && !ids.isEmpty()) {
            for (String s : ids.split(",")) {
                try {
                    int id = Integer.parseInt(s.trim());
                    PendingIntent pi = pending(c, id, "", "");
                    am.cancel(pi);
                    pi.cancel();
                } catch (Throwable ignored) {
                }
            }
        }
        p.edit().putString("ids", "").apply();
        NotificationManager nm = (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) nm.cancelAll();
    }
}

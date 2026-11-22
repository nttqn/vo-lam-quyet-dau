package com.trungsmail.vlauth;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

/** Posts a reminder scheduled by VLNotify; a tap opens the game. */
public class NotifyReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context c, Intent intent) {
        try {
            int id = intent.getIntExtra("id", 1);
            String title = intent.getStringExtra("title");
            String body = intent.getStringExtra("body");
            if (title == null || title.isEmpty()) return;
            VLNotify.ensureChannel(c);
            NotificationManager nm = (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm == null) return;
            Intent open = c.getPackageManager().getLaunchIntentForPackage(c.getPackageName());
            PendingIntent tap = null;
            if (open != null) {
                open.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
                int flags = PendingIntent.FLAG_UPDATE_CURRENT;
                if (Build.VERSION.SDK_INT >= 23) flags |= PendingIntent.FLAG_IMMUTABLE;
                tap = PendingIntent.getActivity(c, 0, open, flags);
            }
            Notification.Builder b = Build.VERSION.SDK_INT >= 26
                    ? new Notification.Builder(c, VLNotify.CHANNEL)
                    : new Notification.Builder(c);
            b.setSmallIcon(R.drawable.vl_notify_icon)
                    .setContentTitle(title)
                    .setContentText(body)
                    .setStyle(new Notification.BigTextStyle().bigText(body))
                    .setAutoCancel(true);
            if (tap != null) b.setContentIntent(tap);
            nm.notify(id, b.build());
        } catch (Throwable ignored) {
            // a reminder must never crash the app process
        }
    }
}

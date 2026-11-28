package com.trungsmail.vlauth;

import android.app.Activity;

import androidx.annotation.NonNull;

import com.google.android.play.core.review.ReviewInfo;
import com.google.android.play.core.review.ReviewManager;
import com.google.android.play.core.review.ReviewManagerFactory;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/**
 * Play in-app review card (1.5.0). The game decides when to ask (Review.gd:
 * after a smooth won fight, 10+ wins); Play decides whether the card shows.
 * Failures are silent by design: the flow never tells whether it was shown.
 */
public class VLReview extends GodotPlugin {
    public VLReview(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "VLReview";
    }

    @UsedByGodot
    public void request() {
        final Activity a = getActivity();
        if (a == null) return;
        a.runOnUiThread(() -> {
            try {
                final ReviewManager m = ReviewManagerFactory.create(a);
                m.requestReviewFlow().addOnCompleteListener(t -> {
                    if (!t.isSuccessful()) return;
                    ReviewInfo info = t.getResult();
                    if (info != null && !a.isFinishing()) {
                        m.launchReviewFlow(a, info);
                    }
                });
            } catch (Throwable ignored) {
                // no Play Store on the phone, or an old one: nothing to do
            }
        });
    }
}

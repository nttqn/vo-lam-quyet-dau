package com.trungsmail.vlauth;

import android.app.Activity;
import android.os.CancellationSignal;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.credentials.Credential;
import androidx.credentials.CredentialManager;
import androidx.credentials.CredentialManagerCallback;
import androidx.credentials.CustomCredential;
import androidx.credentials.GetCredentialRequest;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.exceptions.GetCredentialCancellationException;
import androidx.credentials.exceptions.GetCredentialException;

import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption;
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * Google sign-in for Võ Lâm Quyết Đấu. signIn(webClientId) shows Google's
 * account sheet and answers with one of two signals:
 *   google_token(idToken, email)  - a Google ID token for Firebase signInWithIdp
 *   google_error(kind, message)   - kind "cancel" when the player closed the sheet,
 *                                   else the Credential Manager error type
 */
public class VLGoogleAuth extends GodotPlugin {
    public VLGoogleAuth(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "VLGoogleAuth";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> s = new HashSet<>();
        s.add(new SignalInfo("google_token", String.class, String.class));
        s.add(new SignalInfo("google_error", String.class, String.class));
        return s;
    }

    @UsedByGodot
    public void signIn(String webClientId) {
        final Activity act = getActivity();
        if (act == null) {
            emitSignal("google_error", "noactivity", "");
            return;
        }
        act.runOnUiThread(() -> {
            try {
                GetSignInWithGoogleOption opt = new GetSignInWithGoogleOption.Builder(webClientId).build();
                GetCredentialRequest req = new GetCredentialRequest.Builder().addCredentialOption(opt).build();
                CredentialManager cm = CredentialManager.create(act);
                cm.getCredentialAsync(act, req, new CancellationSignal(), ContextCompat.getMainExecutor(act),
                        new CredentialManagerCallback<GetCredentialResponse, GetCredentialException>() {
                            @Override
                            public void onResult(GetCredentialResponse r) {
                                Credential c = r.getCredential();
                                if (c instanceof CustomCredential
                                        && GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL.equals(c.getType())) {
                                    try {
                                        GoogleIdTokenCredential g = GoogleIdTokenCredential.createFrom(c.getData());
                                        emitSignal("google_token", g.getIdToken(), g.getId());
                                    } catch (Exception e) {
                                        emitSignal("google_error", "parse", String.valueOf(e.getMessage()));
                                    }
                                } else {
                                    emitSignal("google_error", "type", String.valueOf(c.getType()));
                                }
                            }

                            @Override
                            public void onError(@NonNull GetCredentialException e) {
                                String kind = (e instanceof GetCredentialCancellationException) ? "cancel" : String.valueOf(e.getType());
                                emitSignal("google_error", kind, String.valueOf(e.getMessage()));
                            }
                        });
            } catch (Throwable t) {
                emitSignal("google_error", "crash", String.valueOf(t.getMessage()));
            }
        });
    }
}

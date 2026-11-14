package com.adneysousah.herdeiro.updates;

import android.app.Activity;
import android.content.Intent;

import com.google.android.play.core.appupdate.AppUpdateInfo;
import com.google.android.play.core.appupdate.AppUpdateManager;
import com.google.android.play.core.appupdate.AppUpdateManagerFactory;
import com.google.android.play.core.appupdate.AppUpdateOptions;
import com.google.android.play.core.install.model.AppUpdateType;
import com.google.android.play.core.install.model.UpdateAvailability;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * Asks Google Play whether a newer version of the game is published and, when the player
 * agrees, runs Play's own "immediate" in-app update: a full-screen Play page downloads and
 * installs the new version and opens the game again. The game itself never goes online;
 * the Play Store app on the phone does the talking.
 *
 * GDScript side: AppUpdate (scripts/systems/app_update.gd).
 * Build: bash tools/android/build_updates_plugin.sh
 */
public class HerdeiroUpdates extends GodotPlugin {
	private static final int REQUEST_CODE = 4127;

	private AppUpdateManager manager;
	private AppUpdateInfo info;

	public HerdeiroUpdates(Godot godot) {
		super(godot);
	}

	@Override
	public String getPluginName() {
		return "HerdeiroUpdates";
	}

	@Override
	public Set<SignalInfo> getPluginSignals() {
		Set<SignalInfo> signals = new HashSet<>();
		// availability (UpdateAvailability), available version code, immediate allowed,
		// days since Play has the update (-1 unknown), priority (0..5).
		signals.add(new SignalInfo("update_checked", Integer.class, Integer.class, Boolean.class, Integer.class, Integer.class));
		signals.add(new SignalInfo("update_failed", String.class));
		// Activity result of Play's update page (-1 ok, 0 canceled, 1 failed).
		signals.add(new SignalInfo("update_result", Integer.class));
		return signals;
	}

	private AppUpdateManager manager() {
		if (manager == null && getActivity() != null) {
			manager = AppUpdateManagerFactory.create(getActivity());
		}
		return manager;
	}

	/** Asks Play for the newest version; answers with update_checked or update_failed. */
	@UsedByGodot
	public void checkForUpdate() {
		runOnUiThread(() -> {
			AppUpdateManager m = manager();
			if (m == null) {
				emitSignal("update_failed", "no activity");
				return;
			}
			try {
				m.getAppUpdateInfo()
						.addOnSuccessListener(i -> {
							info = i;
							Integer stale = i.clientVersionStalenessDays();
							emitSignal("update_checked", i.updateAvailability(), i.availableVersionCode(),
									i.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE), stale == null ? -1 : stale,
									i.updatePriority());
						})
						.addOnFailureListener(e -> emitSignal("update_failed", String.valueOf(e.getMessage())));
			} catch (Exception e) {
				emitSignal("update_failed", String.valueOf(e));
			}
		});
	}

	/** Opens Play's update page (after update_checked said an update is there). */
	@UsedByGodot
	public void startUpdate() {
		runOnUiThread(() -> {
			Activity activity = getActivity();
			AppUpdateManager m = manager();
			if (activity == null || m == null || info == null) {
				emitSignal("update_failed", "nothing to update");
				return;
			}
			AppUpdateInfo current = info;
			info = null; // each AppUpdateInfo starts one update only
			try {
				if (!m.startUpdateFlowForResult(current, activity, AppUpdateOptions.defaultOptions(AppUpdateType.IMMEDIATE), REQUEST_CODE)) {
					emitSignal("update_failed", "update not allowed");
				}
			} catch (Exception e) {
				emitSignal("update_failed", String.valueOf(e));
			}
		});
	}

	@Override
	public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
		if (requestCode == REQUEST_CODE) {
			emitSignal("update_result", resultCode);
		}
	}

	/** An update the player started and left half-way (game sent to the background): resume it. */
	@Override
	public void onMainResume() {
		if (manager == null) {
			return;
		}
		manager.getAppUpdateInfo().addOnSuccessListener(i -> {
			Activity activity = getActivity();
			if (activity != null && i.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS) {
				try {
					manager.startUpdateFlowForResult(i, activity, AppUpdateOptions.defaultOptions(AppUpdateType.IMMEDIATE), REQUEST_CODE);
				} catch (Exception ignored) {
					// Play shows its own message; the game keeps running on the old version.
				}
			}
		});
	}
}

package com.admai.app

import android.content.Context
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import androidx.annotation.RequiresApi
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Real Android call-screening integration.
 *
 * IMPORTANT — what this can and cannot do:
 * `CallScreeningService` is the only public Android API for inspecting an
 * incoming call before it rings, and it can only ALLOW / REJECT / SILENCE /
 * skip-notification. It cannot inject synthesized speech into the call or
 * have the AI "talk" to the caller — that would require the app to be the
 * default Phone/Dialer (a `ConnectionService` with full real-time audio
 * routing), which is a much larger undertaking than call screening.
 *
 * So this service implements genuine, working call screening:
 *  - numbers the user added to "bloklangan" in the app are auto-rejected
 *  - numbers not in contacts can be auto-silenced when "Tinch rejim" is on
 *  - every decision is appended to `adm_call_screening_log` in
 *    SharedPreferences (the same store `shared_preferences` uses) so the
 *    Flutter Call Center screen can show what was screened and why.
 *
 * Rules are written by the Flutter side (lib/services/call_screening_service.dart)
 * using `SharedPreferences.setString(key, jsonEncode(value))` -- deliberately
 * plain JSON strings rather than `setStringList`, whose Android encoding adds
 * a binary type-tag prefix that's awkward to parse natively. Both sides agree
 * on the "flutter."-prefixed key names the `shared_preferences` plugin uses
 * for its backing SharedPreferences file, so this service can read the rules
 * without a running Dart VM.
 */
@RequiresApi(Build.VERSION_CODES.N)
class AdmCallScreeningService : CallScreeningService() {

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_BLOCKED = "flutter.adm_blocked_numbers_json"
        private const val KEY_QUIET_MODE = "flutter.adm_quiet_mode_enabled"
        private const val KEY_ALLOW_CONTACTS_ONLY = "flutter.adm_allow_contacts_only"
        private const val KEY_KNOWN_CONTACTS = "flutter.adm_known_contacts_json"
        private const val KEY_LOG = "flutter.adm_call_screening_log_json"
        private const val MAX_LOG_ENTRIES = 100
    }

    override fun onScreenCall(callDetails: Call.Details) {
        val number = callDetails.handle?.schemeSpecificPart ?: ""
        val prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        val normalized = normalize(number)
        val blocked = readStringSet(prefs, KEY_BLOCKED)
        val knownContacts = readStringSet(prefs, KEY_KNOWN_CONTACTS)
        val quietMode = prefs.getBoolean(KEY_QUIET_MODE, false)
        val contactsOnly = prefs.getBoolean(KEY_ALLOW_CONTACTS_ONLY, false)

        val isBlocked = blocked.any { normalize(it) == normalized }
        val isKnownContact = knownContacts.any { normalize(it) == normalized }

        val decision: String
        val response = CallResponse.Builder()

        when {
            isBlocked -> {
                decision = "rejected_blocked"
                response.setDisallowCall(true)
                    .setRejectCall(true)
                    .setSkipNotification(true)
            }
            contactsOnly && !isKnownContact -> {
                decision = "silenced_not_contact"
                response.setDisallowCall(false)
                    .setRejectCall(false)
                    .setSilenceCall(true)
            }
            quietMode && !isKnownContact -> {
                decision = "silenced_quiet_mode"
                response.setDisallowCall(false)
                    .setRejectCall(false)
                    .setSilenceCall(true)
            }
            else -> {
                decision = "allowed"
                response.setDisallowCall(false)
                    .setRejectCall(false)
                    .setSilenceCall(false)
            }
        }

        respondToCall(callDetails, response.build())
        appendLog(prefs, normalized, decision)
    }

    private fun normalize(number: String): String = number.filter { it.isDigit() || it == '+' }

    private fun readStringSet(prefs: android.content.SharedPreferences, key: String): Set<String> {
        // The Dart side writes a plain JSON array string via setString(), so a
        // simple getString + JSONArray parse is all that's needed here.
        val raw = prefs.getString(key, null) ?: return emptySet()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { array.getString(it) }.toSet()
        } catch (_: Exception) {
            emptySet()
        }
    }

    private fun appendLog(prefs: android.content.SharedPreferences, number: String, decision: String) {
        val raw = prefs.getString(KEY_LOG, null)
        val existing = try {
            if (raw != null) JSONArray(raw) else JSONArray()
        } catch (_: Exception) {
            JSONArray()
        }

        val entry = JSONObject()
        entry.put("number", number)
        entry.put("decision", decision)
        entry.put("timestamp", SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).format(Date()))

        val updated = JSONArray()
        updated.put(entry)
        val limit = minOf(existing.length(), MAX_LOG_ENTRIES - 1)
        for (i in 0 until limit) {
            updated.put(existing.get(i))
        }

        prefs.edit().putString(KEY_LOG, updated.toString()).apply()
    }
}

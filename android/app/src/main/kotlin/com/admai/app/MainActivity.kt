package com.admai.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.role.RoleManager
import android.content.Intent
import android.media.AudioManager
import android.content.Context
import android.os.Build
import android.provider.Settings
import android.net.Uri

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.admai.app/native"
    private val CALL_SCREENING_CHANNEL = "com.admai.app/call_screening"
    private val REQUEST_CALL_SCREENING_ROLE = 9001

    private var pendingRoleResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_SCREENING_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                }
                "isRoleHeld" -> {
                    result.success(isCallScreeningRoleHeld())
                }
                "requestRole" -> {
                    requestCallScreeningRole(result)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setVolume" -> {
                    val volume = call.argument<Int>("volume") ?: 50
                    setSystemVolume(volume)
                    result.success(null)
                }
                "getVolume" -> {
                    result.success(getSystemVolume())
                }
                "setBrightness" -> {
                    val brightness = call.argument<Int>("brightness") ?: 128
                    setScreenBrightness(brightness)
                    result.success(null)
                }
                "openWifiSettings" -> {
                    startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                    result.success(null)
                }
                "openBluetoothSettings" -> {
                    startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                    result.success(null)
                }
                "getDeviceInfo" -> {
                    result.success(mapOf(
                        "model" to Build.MODEL,
                        "manufacturer" to Build.MANUFACTURER,
                        "androidVersion" to Build.VERSION.RELEASE,
                        "sdkInt" to Build.VERSION.SDK_INT,
                    ))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setSystemVolume(percent: Int) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val volume = (maxVolume * percent / 100.0).toInt()
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volume, 0)
    }

    private fun getSystemVolume(): Int {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val current = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        return (current * 100.0 / max).toInt()
    }

    private fun setScreenBrightness(brightness: Int) {
        if (Settings.System.canWrite(this)) {
            Settings.System.putInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                brightness.coerceIn(0, 255)
            )
        } else {
            val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        }
    }

    // ---- Call screening role (Android 10+) ----
    // Android only lets ONE app at a time hold ROLE_CALL_SCREENING, and only
    // the system role picker can grant it -- apps cannot self-assign it. The
    // user must explicitly approve the system dialog this launches.
    private fun isCallScreeningRoleHeld(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val roleManager = getSystemService(Context.ROLE_SERVICE) as? RoleManager ?: return false
        return roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING) &&
            roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
    }

    private fun requestCallScreeningRole(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(false)
            return
        }
        val roleManager = getSystemService(Context.ROLE_SERVICE) as? RoleManager
        if (roleManager == null || !roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
            result.success(false)
            return
        }
        if (roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
            result.success(true)
            return
        }

        pendingRoleResult = result
        val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
        startActivityForResult(intent, REQUEST_CALL_SCREENING_ROLE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CALL_SCREENING_ROLE) {
            pendingRoleResult?.success(isCallScreeningRoleHeld())
            pendingRoleResult = null
        }
    }
}

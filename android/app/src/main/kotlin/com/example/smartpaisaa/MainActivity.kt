// android/app/src/main/kotlin/com/smartpaisa/MainActivity.kt
package com.smartpaisa

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Bundle
import android.provider.Telephony
import android.telephony.SmsMessage
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.smartpaisa.sms_watcher"
    private var methodChannel: MethodChannel? = null
    private var smsReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startSmsWatcher" -> {
                    startSmsWatcher()
                    result.success("SMS Watcher started")
                }
                "stopSmsWatcher" -> {
                    stopSmsWatcher()
                    result.success("SMS Watcher stopped")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startSmsWatcher() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS)
            != PackageManager.PERMISSION_GRANTED) {
            return
        }

        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
                    val bundle = intent.extras
                    if (bundle != null) {
                        val pdus = bundle.get("pdus") as Array<*>
                        for (pdu in pdus) {
                            val smsMessage = SmsMessage.createFromPdu(pdu as ByteArray)
                            val sender = smsMessage.displayOriginatingAddress
                            val messageBody = smsMessage.messageBody
                            val timestamp = smsMessage.timestampMillis

                            // Send to Flutter
                            val smsData = mapOf(
                                "sender" to sender,
                                "body" to messageBody,
                                "timestamp" to timestamp
                            )

                            methodChannel?.invokeMethod("onSmsReceived", smsData)
                        }
                    }
                }
            }
        }

        val intentFilter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
        intentFilter.priority = 1000
        registerReceiver(smsReceiver, intentFilter)
    }

    private fun stopSmsWatcher() {
        smsReceiver?.let {
            unregisterReceiver(it)
            smsReceiver = null
        }
    }

    override fun onDestroy() {
        stopSmsWatcher()
        super.onDestroy()
    }
}

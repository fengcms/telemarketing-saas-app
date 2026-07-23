package com.example.telemarketing_app

import android.Manifest
import android.content.pm.PackageManager
import android.provider.CallLog
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.telemarketing_app/call_log"
        private const val REQUEST_CALL_LOG = 1001
        // 查询最近 5 分钟的通话记录
        private const val QUERY_WINDOW_MS = 5 * 60 * 1000L
    }

    private var pendingPhoneNumber: String? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "getLatestCallTime") {
                val phone = call.argument<String>("phoneNumber") ?: ""
                handleGetLatestCallTime(phone, result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun handleGetLatestCallTime(phoneNumber: String, result: MethodChannel.Result) {
        // 检查权限
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_CALL_LOG
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            // 未授权 → 请求权限，并暂存 result/phoneNumber 以待回调
            pendingResult = result
            pendingPhoneNumber = phoneNumber
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.READ_CALL_LOG),
                REQUEST_CALL_LOG
            )
            return
        }
        // 已有权限 → 直接查询
        result.success(queryLatestCallTime(phoneNumber))
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_CALL_LOG) return

        val result = pendingResult
        val phone = pendingPhoneNumber
        pendingResult = null
        pendingPhoneNumber = null

        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            result?.success(queryLatestCallTime(phone ?: ""))
        } else {
            // 用户拒绝 → 返回 [-2, 0] 表示无权限
            result?.success(listOf(-2L, 0L))
        }
    }

    /// 查询通话记录：取最近 5 分钟内匹配 phoneNumber 的最新一条通话
    /// 返回 [timestamp(ms), durationSec]；无匹配返回 [-1, 0]
    private fun queryLatestCallTime(phoneNumber: String): List<Long> {
        if (phoneNumber.isBlank()) return listOf(-1L, 0L)

        val cursor = contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            arrayOf(CallLog.Calls.DATE, CallLog.Calls.DURATION),
            "${CallLog.Calls.DATE} >= ? AND ${CallLog.Calls.NUMBER} LIKE ?",
            arrayOf(
                (System.currentTimeMillis() - QUERY_WINDOW_MS).toString(),
                "%${phoneNumber}%"
            ),
            "${CallLog.Calls.DATE} DESC"
        )

        cursor?.use {
            if (it.moveToFirst()) {
                val date = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DATE))
                val duration = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DURATION))
                return listOf(date, duration)
            }
        }
        return listOf(-1L, 0L)
    }
}

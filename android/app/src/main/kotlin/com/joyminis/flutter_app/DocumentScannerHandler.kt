package com.joyminis.flutter_app

import android.app.Activity
import android.content.Intent
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.plugin.common.MethodChannel

class DocumentScannerHandler (private val activity: Activity){
    private var pendingResult: MethodChannel.Result? = null
    val SCAN_REQUEST_CODE = 1001

    // 🚀 启动扫描的方法
    fun startScan(result: MethodChannel.Result) {
        this.pendingResult = result;

        val options = GmsDocumentScannerOptions.Builder()
            .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
            .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
            .setPageLimit(1)
            .setGalleryImportAllowed(false)
            .build()

        val  scanner = GmsDocumentScanning.getClient(options)

        scanner.getStartScanIntent(activity)
            .addOnSuccessListener { intentSender ->
                try {
                    activity.startIntentSenderForResult(intentSender,SCAN_REQUEST_CODE,null,0,0,0)

                }catch (e: Exception){
                   pendingResult?.error("SCAN_START_ERROR",e.message,null)
                    pendingResult = null
                }
            }
            .addOnFailureListener { e ->
               pendingResult?.error("SCAN_INIT_FAILED",e.message,null)
            }
    }

    // 📸 处理返回结果的方法
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != SCAN_REQUEST_CODE)  return  false;

        val result = GmsDocumentScanningResult.fromActivityResultIntent(data)
        if (resultCode == Activity.RESULT_OK && result != null){
            val  pages = result.pages
            if (pages != null && pages.isNotEmpty()){
                val  imageUrl = pages[0].imageUri
                pendingResult?.success(imageUrl.toString())
            }else{
                pendingResult?.success(null)
            }
        }else{
            pendingResult?.success(null)
        }
        pendingResult = null// 用完即焚，防止内存泄漏
        return true

    }
}
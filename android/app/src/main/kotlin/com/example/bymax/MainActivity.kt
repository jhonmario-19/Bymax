package com.example.bymax 

import io.flutter.embedding.android.FlutterActivity
import android.os.Build
import android.os.Bundle
import android.window.OnBackInvokedDispatcher
import android.window.OnBackInvokedCallback

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (Build.VERSION.SDK_INT >= 33) {
            try {
                val callback = OnBackInvokedCallback {
                    // Puedes manejar la acción aquí si es necesario
                    // O dejar que Flutter lo maneje
                    onBackPressed()
                }
                onBackInvokedDispatcher.registerOnBackInvokedCallback(
                    OnBackInvokedDispatcher.PRIORITY_DEFAULT,
                    callback
                )
            } catch (e: Exception) {
                // Manejar posibles excepciones
            }
        }
    }
}
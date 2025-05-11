package com.example.mobile_app_assignment

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.google.android.gms.maps.MapsInitializer // Correct import
import com.google.android.gms.maps.MapsInitializer.Renderer // Import for Renderer enum

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // No need to manually register GoogleMapsPlugin with v2 embedding
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Initialize Google Maps with explicit type for the renderer callback
        MapsInitializer.initialize(applicationContext, MapsInitializer.Renderer.LATEST) { renderer: Renderer ->
            // Optional: Log the renderer used (LATEST or LEGACY)
            println("Google Maps Renderer: $renderer")
        }
    }
}
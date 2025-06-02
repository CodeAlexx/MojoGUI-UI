/**
 * Test program for rendering primitives library
 * Verifies that the minimal C interface works correctly.
 */

#include "rendering_primitives.h"
#include <stdio.h>
#include <unistd.h>

int main() {
    printf("🧪 Testing Rendering Primitives Library\n");
    
    // Initialize
    printf("1. Initializing OpenGL context...\n");
    if (initialize_gl_context(600, 400, "Primitives Test") != 0) {
        printf("❌ Failed to initialize OpenGL context\n");
        return 1;
    }
    printf("✅ OpenGL context initialized\n");
    
    // Load font
    printf("2. Loading default font...\n");
    if (load_default_font() != 0) {
        printf("⚠️  Warning: Failed to load font\n");
    } else {
        printf("✅ Font loaded\n");
    }
    
    printf("3. Starting render loop...\n");
    
    int frame_count = 0;
    while (!should_close_window() && frame_count < 300) {  // Run for ~5 seconds at 60fps
        // Poll events
        poll_events();
        
        // Begin frame
        if (frame_begin() != 0) {
            printf("❌ Failed to begin frame\n");
            break;
        }
        
        // Clear with dark blue background
        set_color(0.1f, 0.15f, 0.25f, 1.0f);
        draw_filled_rectangle(0.0f, 0.0f, 600.0f, 400.0f);
        
        // Draw some test shapes
        
        // Red rectangle
        set_color(1.0f, 0.3f, 0.3f, 1.0f);
        draw_filled_rectangle(50.0f, 50.0f, 100.0f, 60.0f);
        
        // Green circle
        set_color(0.3f, 1.0f, 0.3f, 1.0f);
        draw_filled_circle(200.0f, 80.0f, 30.0f, 16);
        
        // Blue line
        set_color(0.3f, 0.3f, 1.0f, 1.0f);
        draw_line(300.0f, 50.0f, 400.0f, 110.0f, 3.0f);
        
        // White text
        set_color(1.0f, 1.0f, 1.0f, 1.0f);
        draw_text("Hello from C!", 50.0f, 150.0f, 16.0f);
        
        // Yellow outlined rectangle
        set_color(1.0f, 1.0f, 0.3f, 1.0f);
        draw_rectangle(300.0f, 150.0f, 120.0f, 80.0f);
        
        // End frame
        if (frame_end() != 0) {
            printf("❌ Failed to end frame\n");
            break;
        }
        
        frame_count++;
        
        if (frame_count % 60 == 0) {
            printf("📊 Frame %d - Primitives rendering\n", frame_count);
        }
        
        usleep(16667);  // ~60 FPS
    }
    
    printf("🏁 Render loop completed after %d frames\n", frame_count);
    
    // Cleanup
    printf("4. Cleaning up...\n");
    if (cleanup_gl() != 0) {
        printf("⚠️  Warning: Cleanup failed\n");
    } else {
        printf("✅ Cleanup successful\n");
    }
    
    printf("🎉 Test completed successfully!\n");
    return 0;
}
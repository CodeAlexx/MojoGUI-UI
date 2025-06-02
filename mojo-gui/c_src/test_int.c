/**
 * Test program for integer-only rendering primitives library
 */

#include "rendering_primitives_int.h"
#include <stdio.h>
#include <unistd.h>

int main() {
    printf("🧪 Testing Integer-Only Rendering Primitives\n");
    
    // Initialize
    printf("1. Initializing OpenGL context...\n");
    if (initialize_gl_context(600, 400, "Integer Test") != 0) {
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
    
    printf("3. Starting integer render loop...\n");
    
    int frame_count = 0;
    while (!should_close_window() && frame_count < 180) {  // Run for ~3 seconds
        // Poll events
        poll_events();
        
        // Begin frame
        if (frame_begin() != 0) {
            printf("❌ Failed to begin frame\n");
            break;
        }
        
        // Clear with dark background (RGB 25, 40, 65)
        set_color(25, 40, 65, 255);
        draw_filled_rectangle(0, 0, 600, 400);
        
        // Draw colorful shapes using integer coordinates
        
        // Red rectangle (RGB 255, 80, 80)
        set_color(255, 80, 80, 255);
        draw_filled_rectangle(50, 50, 100, 60);
        
        // Green circle (RGB 80, 255, 80)
        set_color(80, 255, 80, 255);
        draw_filled_circle(200, 80, 30, 16);
        
        // Blue line (RGB 80, 80, 255)
        set_color(80, 80, 255, 255);
        draw_line(300, 50, 400, 110, 3);
        
        // White text (RGB 255, 255, 255)
        set_color(255, 255, 255, 255);
        draw_text("Integer FFI Test!", 50, 150, 16);
        
        // Yellow outlined rectangle (RGB 255, 255, 80)
        set_color(255, 255, 80, 255);
        draw_rectangle(300, 150, 120, 80);
        
        // Purple filled circle (RGB 200, 80, 200)
        set_color(200, 80, 200, 255);
        draw_filled_circle(450, 180, 25, 12);
        
        // Test mouse position display
        int mx = get_mouse_x();
        int my = get_mouse_y();
        
        // Draw mouse position indicator (cyan)
        set_color(80, 255, 255, 255);
        draw_filled_circle(mx, my, 5, 8);
        
        // End frame
        if (frame_end() != 0) {
            printf("❌ Failed to end frame\n");
            break;
        }
        
        frame_count++;
        
        if (frame_count % 60 == 0) {
            printf("📊 Frame %d - Mouse at (%d, %d)\n", frame_count, mx, my);
        }
        
        usleep(16667);  // ~60 FPS
    }
    
    printf("🏁 Integer render loop completed after %d frames\n", frame_count);
    
    // Cleanup
    printf("4. Cleaning up...\n");
    if (cleanup_gl() != 0) {
        printf("⚠️  Warning: Cleanup failed\n");
    } else {
        printf("✅ Cleanup successful\n");
    }
    
    printf("🎉 Integer-only test completed successfully!\n");
    return 0;
}
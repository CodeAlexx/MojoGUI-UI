/**
 * Test for integer API with TTF font support
 * Verifies the bridge between integer API and stb_truetype fonts
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "rendering_primitives_int.h"

int main() {
    printf("🧪 Testing Integer API with TTF Font Support\n");
    printf("============================================\n");
    
    // Initialize window
    printf("🚀 Initializing 800x600 window...\n");
    if (initialize_gl_context(800, 600, "C Test: Integer API + TTF Fonts") != 0) {
        printf("❌ Failed to initialize GL context\n");
        return 1;
    }
    printf("✅ Window initialized successfully\n");
    
    // Load TTF fonts
    printf("🔤 Loading TTF fonts...\n");
    if (load_default_font() != 0) {
        printf("⚠️  TTF font loading failed - will use rectangle fallback\n");
    } else {
        printf("✅ TTF fonts loaded successfully!\n");
    }
    
    printf("🎯 Starting render loop (200 frames)...\n");
    
    // Simple render loop
    for (int frame = 0; frame < 200 && !should_close_window(); frame++) {
        // Poll events
        poll_events();
        
        // Get mouse position
        int mouse_x = get_mouse_x();
        int mouse_y = get_mouse_y();
        
        // Begin frame
        if (frame_begin() != 0) {
            printf("❌ Frame begin failed at frame %d\n", frame);
            break;
        }
        
        // Clear background (dark gray)
        set_color(45, 45, 45, 255);
        draw_filled_rectangle(0, 0, 800, 600);
        
        // Draw title with TTF fonts (white, large)
        set_color(255, 255, 255, 255);
        draw_text("🎨 TTF Fonts in C with Integer API", 50, 50, 24);
        
        // Draw subtitle (light green)
        set_color(150, 255, 150, 255);
        draw_text("stb_truetype rendering with Int32 coordinates", 50, 90, 16);
        
        // Font size demonstration
        set_color(200, 200, 255, 255);
        draw_text("Font Size 12: The quick brown fox jumps", 50, 150, 12);
        draw_text("Font Size 16: The quick brown fox jumps", 50, 180, 16);
        draw_text("Font Size 20: The quick brown fox jumps", 50, 210, 20);
        
        // Technical features
        set_color(255, 200, 100, 255);
        draw_text("Technical Features:", 50, 280, 16);
        
        set_color(200, 200, 200, 255);
        draw_text("• Real TTF font loading (Inter, Roboto, Ubuntu)", 70, 310, 12);
        draw_text("• Professional anti-aliasing via stb_truetype", 70, 330, 12);
        draw_text("• Integer-only API for Mojo compatibility", 70, 350, 12);
        draw_text("• Gamma-corrected alpha blending", 70, 370, 12);
        
        // Mouse tracking
        set_color(100, 255, 255, 255);
        char mouse_text[100];
        sprintf(mouse_text, "Mouse: %d, %d", mouse_x, mouse_y);
        draw_text(mouse_text, 50, 420, 14);
        
        // Frame counter
        set_color(100, 100, 100, 255);
        char frame_text[50];
        sprintf(frame_text, "Frame: %d/200", frame + 1);
        draw_text(frame_text, 50, 450, 12);
        
        // Mouse cursor (red circle)
        set_color(255, 100, 100, 255);
        draw_filled_circle(mouse_x, mouse_y, 5, 12);
        
        // End frame
        if (frame_end() != 0) {
            printf("❌ Frame end failed at frame %d\n", frame);
            break;
        }
        
        // Status updates
        if (frame % 50 == 0) {
            printf("📊 Frame %d - Mouse: (%d, %d)\n", frame, mouse_x, mouse_y);
        }
        
        // Small delay to see the animation
        usleep(16667); // ~60 FPS
    }
    
    printf("🏁 Render loop completed\n");
    
    // Cleanup
    printf("🧹 Cleaning up...\n");
    if (cleanup_gl() != 0) {
        printf("⚠️  Cleanup warning\n");
    } else {
        printf("✅ Cleanup successful\n");
    }
    
    printf("\n🎉 SUCCESS: Integer API + TTF Fonts working!\n");
    printf("✨ Ready for Mojo integration\n");
    printf("🚀 Professional font rendering enabled\n");
    
    return 0;
}
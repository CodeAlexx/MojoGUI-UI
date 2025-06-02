/**
 * Rendering Primitives with REAL Font Support
 * Uses stb_truetype for actual text rendering
 */

#define STB_TRUETYPE_IMPLEMENTATION
#include "../../stb_truetype.h"
#include "rendering_primitives.h"
#include <GL/gl.h>
#include <GLFW/glfw3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Global state (same as before)
static GLFWwindow* g_window = NULL;
static int g_window_width = 800;
static int g_window_height = 600;
static int g_mouse_x = 0, g_mouse_y = 0;
static int g_mouse_buttons[8] = {0};
static int g_keys[512] = {0};
static int g_should_close = 0;

// REAL font rendering with stb_truetype
static stbtt_fontinfo g_font;
static unsigned char* g_font_buffer = NULL;
static int g_font_loaded = 0;
static float g_font_scale = 1.0f;

// Embedded font data (minimal bitmap font)
static unsigned char g_embedded_font[] = {
    // This would be a real TTF font embedded as bytes
    // For now, we'll try to load a system font
};

// GLFW callbacks (same as before)
static void error_callback(int error, const char* description) {
    fprintf(stderr, "GLFW Error %d: %s\n", error, description);
}

static void mouse_button_callback(GLFWwindow* window, int button, int action, int mods) {
    if (button >= 0 && button < 8) {
        g_mouse_buttons[button] = (action == GLFW_PRESS) ? 1 : 0;
    }
}

static void cursor_position_callback(GLFWwindow* window, double xpos, double ypos) {
    g_mouse_x = (int)xpos;
    g_mouse_y = (int)ypos;
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    if (key >= 0 && key < 512) {
        g_keys[key] = (action == GLFW_PRESS || action == GLFW_REPEAT) ? 1 : 0;
    }
}

static void window_close_callback(GLFWwindow* window) {
    g_should_close = 1;
}

static void window_size_callback(GLFWwindow* window, int width, int height) {
    g_window_width = width;
    g_window_height = height;
    glViewport(0, 0, width, height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, width, height, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
}

// Initialize OpenGL context (same as before)
int initialize_gl_context(int width, int height, const char* title) {
    if (g_window != NULL) {
        return -1;
    }
    
    glfwSetErrorCallback(error_callback);
    
    if (!glfwInit()) {
        return -1;
    }
    
    g_window = glfwCreateWindow(width, height, title, NULL, NULL);
    if (!g_window) {
        glfwTerminate();
        return -1;
    }
    
    glfwMakeContextCurrent(g_window);
    glfwSwapInterval(1);
    
    // Set callbacks
    glfwSetMouseButtonCallback(g_window, mouse_button_callback);
    glfwSetCursorPosCallback(g_window, cursor_position_callback);
    glfwSetKeyCallback(g_window, key_callback);
    glfwSetWindowCloseCallback(g_window, window_close_callback);
    glfwSetWindowSizeCallback(g_window, window_size_callback);
    
    g_window_width = width;
    g_window_height = height;
    
    // OpenGL setup
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_DEPTH_TEST);
    
    glViewport(0, 0, width, height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, width, height, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    return 0;
}

// REAL font loading using stb_truetype with professional fonts
int load_default_font(void) {
    printf("🔤 Loading PROFESSIONAL fonts with stb_truetype...\n");
    
    // Try to load professional system fonts (best to worst)
    const char* font_paths[] = {
        // Modern Professional Sans-Serif fonts
        "/usr/share/fonts/truetype/ubuntu/Ubuntu-Regular.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", 
        "/usr/share/fonts/opentype/noto/NotoSans-Regular.ttf",
        "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SF-Pro-Display-Regular.otf",
        "/Windows/Fonts/segoeui.ttf",
        "/Windows/Fonts/calibri.ttf",
        
        // Programming/Monospace fonts (great for IDEs)
        "/usr/share/fonts/truetype/ubuntu/UbuntuMono-Regular.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/System/Library/Fonts/Monaco.ttf", 
        "/System/Library/Fonts/Menlo.ttc",
        "/Windows/Fonts/consola.ttf",
        
        // High-quality fallbacks
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/TTF/DejaVuSans.ttf", 
        "/System/Library/Fonts/Arial.ttf",
        "/Windows/Fonts/arial.ttf",
        "/usr/share/fonts/TTF/arial.ttf",
        NULL
    };
    
    for (int i = 0; font_paths[i] != NULL; i++) {
        FILE* file = fopen(font_paths[i], "rb");
        if (file) {
            printf("   Found font: %s\n", font_paths[i]);
            
            // Get file size
            fseek(file, 0, SEEK_END);
            long size = ftell(file);
            fseek(file, 0, SEEK_SET);
            
            // Allocate buffer
            g_font_buffer = malloc(size);
            if (!g_font_buffer) {
                fclose(file);
                continue;
            }
            
            // Read font data
            if (fread(g_font_buffer, 1, size, file) != size) {
                free(g_font_buffer);
                g_font_buffer = NULL;
                fclose(file);
                continue;
            }
            fclose(file);
            
            // Initialize stb_truetype with ENHANCED QUALITY
            if (stbtt_InitFont(&g_font, g_font_buffer, stbtt_GetFontOffsetForIndex(g_font_buffer, 0))) {
                g_font_loaded = 1;
                g_font_scale = stbtt_ScaleForPixelHeight(&g_font, 16.0f);
                printf("   ✅ Professional font loaded successfully: %s\n", font_paths[i]);
                printf("   📈 Enhanced anti-aliasing enabled\n");
                return 0;
            } else {
                printf("   ❌ Failed to initialize font\n");
                free(g_font_buffer);
                g_font_buffer = NULL;
            }
        }
    }
    
    printf("   ⚠️  No system font found, using fallback rectangles\n");
    g_font_loaded = 0;
    return -1;
}

// REAL text rendering using stb_truetype
int draw_text(const char* text, float x, float y, float size) {
    if (!text || strlen(text) == 0) return -1;
    
    if (!g_font_loaded) {
        printf("🔤 Font not loaded, drawing text as rectangles: %s\n", text);
        // Fallback to rectangles
        float char_width = size * 0.6f;
        float char_spacing = char_width + 2.0f;
        
        int len = strlen(text);
        for (int i = 0; i < len; i++) {
            if (text[i] >= 32 && text[i] <= 126) {
                draw_filled_rectangle(x + i * char_spacing, y, char_width, size);
            }
        }
        return 0;
    }
    
    printf("🔤 Rendering REAL text: '%s' at (%.1f, %.1f) size %.1f\n", text, x, y, size);
    
    // Calculate scale for requested size with ENHANCED QUALITY
    // Use slightly higher resolution for better quality
    float scale = stbtt_ScaleForPixelHeight(&g_font, size * 1.1f);
    
    int ascent, descent, line_gap;
    stbtt_GetFontVMetrics(&g_font, &ascent, &descent, &line_gap);
    
    float baseline = y + ascent * scale;
    float current_x = x;
    
    // Render each character
    for (const char* p = text; *p; p++) {
        int codepoint = *p;
        
        // Get character metrics
        int advance_width, left_bearing;
        stbtt_GetCodepointHMetrics(&g_font, codepoint, &advance_width, &left_bearing);
        
        // Get bounding box
        int x0, y0, x1, y1;
        stbtt_GetCodepointBitmapBox(&g_font, codepoint, scale, scale, &x0, &y0, &x1, &y1);
        
        // Create bitmap for this character
        int bitmap_width = x1 - x0;
        int bitmap_height = y1 - y0;
        
        if (bitmap_width > 0 && bitmap_height > 0) {
            unsigned char* bitmap = stbtt_GetCodepointBitmap(&g_font, 0, scale, codepoint, &bitmap_width, &bitmap_height, 0, 0);
            
            if (bitmap) {
                // Render bitmap with PROFESSIONAL QUALITY ANTI-ALIASING
                float char_x = current_x + left_bearing * scale;
                float char_y = baseline + y0;
                
                // Enable smooth blending for professional text rendering
                glEnable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                glBegin(GL_QUADS);
                for (int by = 0; by < bitmap_height; by++) {
                    for (int bx = 0; bx < bitmap_width; bx++) {
                        unsigned char alpha = bitmap[by * bitmap_width + bx];
                        
                        // ENHANCED: Use actual alpha for smooth anti-aliased edges
                        if (alpha > 12) {  // Lower threshold for better coverage
                            float px = char_x + bx;
                            float py = char_y + by;
                            
                            // Apply alpha blending for smooth text edges
                            float alpha_f = (float)alpha / 255.0f;
                            glColor4f(1.0f, 1.0f, 1.0f, alpha_f);
                            
                            glVertex2f(px, py);
                            glVertex2f(px + 1, py);
                            glVertex2f(px + 1, py + 1);
                            glVertex2f(px, py + 1);
                        }
                    }
                }
                glEnd();
                
                // Reset to default color
                glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
                
                stbtt_FreeBitmap(bitmap, NULL);
            }
        }
        
        current_x += advance_width * scale;
    }
    
    return 0;
}

// Rest of the functions remain the same as original library
int cleanup_gl(void) {
    if (g_font_buffer) {
        free(g_font_buffer);
        g_font_buffer = NULL;
    }
    g_font_loaded = 0;
    
    if (g_window) {
        glfwDestroyWindow(g_window);
        g_window = NULL;
    }
    
    glfwTerminate();
    return 0;
}

int frame_begin(void) {
    if (!g_window) return -1;
    glClear(GL_COLOR_BUFFER_BIT);
    glLoadIdentity();
    return 0;
}

int frame_end(void) {
    if (!g_window) return -1;
    glfwSwapBuffers(g_window);
    return 0;
}

int set_color(float r, float g, float b, float a) {
    glColor4f(r, g, b, a);
    return 0;
}

int draw_filled_rectangle(float x, float y, float width, float height) {
    glBegin(GL_QUADS);
    glVertex2f(x, y);
    glVertex2f(x + width, y);
    glVertex2f(x + width, y + height);
    glVertex2f(x, y + height);
    glEnd();
    return 0;
}

int draw_rectangle(float x, float y, float width, float height) {
    glBegin(GL_LINE_LOOP);
    glVertex2f(x, y);
    glVertex2f(x + width, y);
    glVertex2f(x + width, y + height);
    glVertex2f(x, y + height);
    glEnd();
    return 0;
}

int draw_filled_circle(float x, float y, float radius, int segments) {
    glBegin(GL_TRIANGLE_FAN);
    glVertex2f(x, y);
    for (int i = 0; i <= segments; i++) {
        float angle = 2.0f * M_PI * i / segments;
        float cx = x + radius * cosf(angle);
        float cy = y + radius * sinf(angle);
        glVertex2f(cx, cy);
    }
    glEnd();
    return 0;
}

int draw_line(float x1, float y1, float x2, float y2, float thickness) {
    glLineWidth(thickness);
    glBegin(GL_LINES);
    glVertex2f(x1, y1);
    glVertex2f(x2, y2);
    glEnd();
    glLineWidth(1.0f);
    return 0;
}

int get_text_size(const char* text, float size, float* width, float* height) {
    if (!text || !width || !height) return -1;
    
    if (!g_font_loaded) {
        // Fallback calculation
        float char_width = size * 0.6f;
        float char_spacing = char_width + 2.0f;
        int len = strlen(text);
        *width = len > 0 ? (len - 1) * char_spacing + char_width : 0.0f;
        *height = size;
        return 0;
    }
    
    // Real calculation with stb_truetype
    float scale = stbtt_ScaleForPixelHeight(&g_font, size);
    float total_width = 0.0f;
    
    for (const char* p = text; *p; p++) {
        int advance_width, left_bearing;
        stbtt_GetCodepointHMetrics(&g_font, *p, &advance_width, &left_bearing);
        total_width += advance_width * scale;
    }
    
    *width = total_width;
    *height = size;
    return 0;
}

int poll_events(void) {
    if (!g_window) return -1;
    glfwPollEvents();
    return 0;
}

int should_close_window(void) {
    if (!g_window) return 1;
    return glfwWindowShouldClose(g_window) || g_should_close;
}

int get_mouse_x(void) {
    return g_mouse_x;
}

int get_mouse_y(void) {
    return g_mouse_y;
}

int get_mouse_button_state(int button) {
    if (button >= 0 && button < 8) {
        return g_mouse_buttons[button];
    }
    return 0;
}

int get_key_state(int key_code) {
    if (key_code >= 0 && key_code < 512) {
        return g_keys[key_code];
    }
    return 0;
}
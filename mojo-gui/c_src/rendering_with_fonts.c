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

// PROFESSIONAL FONT RENDERING with glyph atlas
static stbtt_fontinfo g_font;
static unsigned char* g_font_buffer = NULL;
static int g_font_loaded = 0;
static float g_font_scale = 1.0f;

// Glyph atlas system for smooth, efficient text rendering
static GLuint g_font_texture = 0;
static stbtt_bakedchar g_baked_chars[96]; // ASCII 32-127
static int g_atlas_width = 512;
static int g_atlas_height = 512;
static float g_font_size = 48.0f; // High resolution for scaling

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
    
    // JETBRAINS MONO ONLY - No fallbacks!
    const char* font_paths[] = {
        // ONLY JetBrains Mono paths (multiple locations for robustness)
        "/home/alex/.local/share/fonts/jetbrains/JetBrainsMono-Regular.ttf",
        "/home/alex/.local/share/fonts/jetbrains/JetBrainsMono-Bold.ttf",
        "/home/alex/.local/share/fonts/JetBrainsMono-Regular.ttf",
        "/usr/share/fonts/truetype/jetbrains/JetBrainsMono-Regular.ttf",
        "/usr/local/share/fonts/JetBrainsMono-Regular.ttf",
        "/usr/share/fonts/JetBrainsMono-Regular.ttf",
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
            
            // Initialize stb_truetype with PROFESSIONAL GLYPH ATLAS
            if (stbtt_InitFont(&g_font, g_font_buffer, stbtt_GetFontOffsetForIndex(g_font_buffer, 0))) {
                // Create high-resolution glyph atlas
                unsigned char* atlas_bitmap = malloc(g_atlas_width * g_atlas_height);
                if (!atlas_bitmap) {
                    printf("   ❌ Failed to allocate atlas bitmap\n");
                    free(g_font_buffer);
                    g_font_buffer = NULL;
                    continue;
                }
                
                // Bake ASCII characters 32-127 into atlas at high resolution
                int bake_result = stbtt_BakeFontBitmap(g_font_buffer, 0, g_font_size, 
                                                      atlas_bitmap, g_atlas_width, g_atlas_height, 
                                                      32, 96, g_baked_chars);
                
                if (bake_result > 0) {
                    // Create OpenGL texture for the atlas
                    glGenTextures(1, &g_font_texture);
                    glBindTexture(GL_TEXTURE_2D, g_font_texture);
                    
                    // Upload atlas with proper filtering for smooth text
                    glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, g_atlas_width, g_atlas_height, 
                                0, GL_ALPHA, GL_UNSIGNED_BYTE, atlas_bitmap);
                    
                    // Enable linear filtering for smooth scaling
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                    
                    glBindTexture(GL_TEXTURE_2D, 0);
                    
                    g_font_loaded = 1;
                    printf("   ✅ Professional font loaded successfully: %s\n", font_paths[i]);
                    printf("   🎨 High-resolution glyph atlas created (%dx%d)\n", g_atlas_width, g_atlas_height);
                    printf("   📈 Smooth anti-aliasing enabled with linear filtering\n");
                    
                    free(atlas_bitmap);
                    return 0;
                } else {
                    printf("   ❌ Failed to bake font atlas\n");
                    free(atlas_bitmap);
                    free(g_font_buffer);
                    g_font_buffer = NULL;
                }
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

// PROFESSIONAL TEXT RENDERING using pre-baked glyph atlas
int draw_text(const char* text, float x, float y, float size) {
    if (!text || strlen(text) == 0) return -1;
    
    if (!g_font_loaded || g_font_texture == 0) {
        printf("🔤 Font atlas not loaded, drawing text as rectangles: %s\n", text);
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
    
    printf("🔤 Rendering SMOOTH atlas text: '%s' at (%.1f, %.1f) size %.1f\n", text, x, y, size);
    
    // Calculate scale factor from atlas size to requested size
    float scale = size / g_font_size;
    
    // Enable professional text rendering
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Bind the pre-baked glyph atlas
    glBindTexture(GL_TEXTURE_2D, g_font_texture);
    
    float current_x = 0.0f; // Start at 0 for GetBakedQuad
    float current_y = 0.0f;
    
    // Render each character using the atlas
    for (const char* p = text; *p; p++) {
        int c = (int)*p;
        
        // Only render printable ASCII characters
        if (c >= 32 && c < 128) {
            int char_index = c - 32;
            
            // Get pre-baked quad data with subpixel positioning
            stbtt_aligned_quad quad;
            stbtt_GetBakedQuad(g_baked_chars, g_atlas_width, g_atlas_height, 
                              char_index, &current_x, &current_y, &quad, 1);
            
            // Scale and position the quad
            float x0 = x + quad.x0 * scale;
            float y0 = y + quad.y0 * scale;
            float x1 = x + quad.x1 * scale;
            float y1 = y + quad.y1 * scale;
            
            // Render smooth textured quad from atlas
            glBegin(GL_QUADS);
                glTexCoord2f(quad.s0, quad.t0); glVertex2f(x0, y0);
                glTexCoord2f(quad.s1, quad.t0); glVertex2f(x1, y0);
                glTexCoord2f(quad.s1, quad.t1); glVertex2f(x1, y1);
                glTexCoord2f(quad.s0, quad.t1); glVertex2f(x0, y1);
            glEnd();
        } else {
            // For non-printable characters, advance by average character width
            current_x += g_font_size * 0.5f;
        }
    }
    
    // Cleanup
    glBindTexture(GL_TEXTURE_2D, 0);
    glDisable(GL_TEXTURE_2D);
    
    return 0;
}

// Cleanup function with proper atlas texture cleanup
int cleanup_gl(void) {
    // Clean up font atlas texture
    if (g_font_texture != 0) {
        glDeleteTextures(1, &g_font_texture);
        g_font_texture = 0;
    }
    
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
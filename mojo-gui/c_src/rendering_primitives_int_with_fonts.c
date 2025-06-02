/**
 * Integer-Only Rendering Primitives with REAL TTF Font Support
 * 
 * This is the bridge library that provides integer-only API for Mojo
 * while using the complete stb_truetype implementation internally.
 * 
 * Solves the problem: Mojo uses integer API but we want real TTF fonts.
 * Solution: Integer wrapper around the float-based TTF implementation.
 */

// Enable popen/pclose on Linux
#define _GNU_SOURCE

#define STB_TRUETYPE_IMPLEMENTATION
#include "../../stb_truetype.h"
#include "rendering_primitives_int.h"
#include <GL/gl.h>
#include <GLFW/glfw3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Global state (same pattern as original)
static GLFWwindow* g_window = NULL;
static int g_window_width = 800;
static int g_window_height = 600;
static int g_mouse_x = 0, g_mouse_y = 0;
static int g_mouse_buttons[8] = {0};
static int g_keys[512] = {0};
static int g_should_close = 0;

// Character input support for text fields
static char g_input_buffer[256] = {0};
static int g_input_buffer_pos = 0;
static int g_has_new_input = 0;

// REAL font rendering with stb_truetype (same as rendering_with_fonts.c)
static stbtt_fontinfo g_font;
static unsigned char* g_font_buffer = NULL;
static int g_font_loaded = 0;
static float g_font_scale = 1.0f;

// GLFW callbacks (same as before)
static void error_callback(int error, const char* description) {
    fprintf(stderr, "GLFW Error %d: %s\n", error, description);
}

static void mouse_button_callback(GLFWwindow* window, int button, int action, int mods) {
    (void)window; (void)mods;
    if (button >= 0 && button < 8) {
        g_mouse_buttons[button] = (action == GLFW_PRESS) ? 1 : 0;
    }
}

static void cursor_position_callback(GLFWwindow* window, double xpos, double ypos) {
    (void)window;
    g_mouse_x = (int)xpos;
    g_mouse_y = (int)ypos;
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    (void)window; (void)scancode; (void)mods;
    if (key >= 0 && key < 512) {
        g_keys[key] = (action == GLFW_PRESS || action == GLFW_REPEAT) ? 1 : 0;
    }
    
    // Handle backspace for text input (GLFW_KEY_BACKSPACE = 259)
    if (key == 259 && (action == GLFW_PRESS || action == GLFW_REPEAT)) {
        if (g_input_buffer_pos > 0) {
            g_input_buffer_pos--;
            g_input_buffer[g_input_buffer_pos] = '\0';
            g_has_new_input = 1;
        }
    }
}

static void character_callback(GLFWwindow* window, unsigned int codepoint) {
    (void)window;
    
    // Only accept printable ASCII characters for simplicity
    if (codepoint >= 32 && codepoint < 127 && g_input_buffer_pos < 255) {
        g_input_buffer[g_input_buffer_pos] = (char)codepoint;
        g_input_buffer_pos++;
        g_input_buffer[g_input_buffer_pos] = '\0';
        g_has_new_input = 1;
    }
}

static void window_close_callback(GLFWwindow* window) {
    (void)window;
    g_should_close = 1;
}

static void window_size_callback(GLFWwindow* window, int width, int height) {
    (void)window;
    g_window_width = width;
    g_window_height = height;
    glViewport(0, 0, width, height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, width, height, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
}

// Initialize OpenGL context (same as original)
int initialize_gl_context(int width, int height, const char* title) {
    if (g_window != NULL) {
        return -1;
    }
    
    glfwSetErrorCallback(error_callback);
    
    if (!glfwInit()) {
        return -1;
    }
    
    g_window = glfwCreateWindow(width, height, title ? title : "Mojo GUI with TTF Fonts", NULL, NULL);
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
    glfwSetCharCallback(g_window, character_callback);
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

// REAL font loading with stb_truetype (copy from rendering_with_fonts.c)
int load_default_font(void) {
    printf("🔤 Loading MODERN FONTS for Mojo with stb_truetype...\n");
    
    // Modern UI fonts (same list as rendering_with_fonts.c)
    const char* font_paths[] = {
        // TIER 1: Modern UI Fonts
        "/usr/share/fonts/truetype/inter/Inter-Regular.ttf",
        "/usr/share/fonts/truetype/roboto/Roboto-Regular.ttf",
        "/usr/share/fonts/opentype/source-sans-pro/SourceSansPro-Regular.otf",
        "/usr/share/fonts/truetype/source-sans-pro/SourceSansPro-Regular.ttf",
        "/Windows/Fonts/segoeui.ttf",
        "/System/Library/Fonts/SF-Pro-Display-Regular.otf",
        "/System/Library/Fonts/SF-Pro-Text-Regular.otf",
        
        // TIER 2: High-Quality Professional Fonts
        "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
        "/usr/share/fonts/opentype/noto/NotoSans-Regular.ttf",
        "/usr/share/fonts/truetype/ubuntu/Ubuntu-Regular.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Windows/Fonts/calibri.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        
        // Programming fonts
        "/usr/share/fonts/truetype/ubuntu/UbuntuMono-Regular.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/System/Library/Fonts/Monaco.ttf", 
        "/System/Library/Fonts/Menlo.ttc",
        "/Windows/Fonts/consola.ttf",
        
        // Fallbacks
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
            
            // Initialize stb_truetype
            if (stbtt_InitFont(&g_font, g_font_buffer, stbtt_GetFontOffsetForIndex(g_font_buffer, 0))) {
                g_font_loaded = 1;
                g_font_scale = stbtt_ScaleForPixelHeight(&g_font, 16.0f);
                printf("   ✅ TTF FONT loaded for Mojo: %s\n", font_paths[i]);
                printf("   ✨ Integer API with professional font rendering enabled\n");
                return 0;
            } else {
                printf("   ❌ Failed to initialize font\n");
                free(g_font_buffer);
                g_font_buffer = NULL;
            }
        }
    }
    
    printf("   ⚠️  No TTF font found, using rectangle fallback\n");
    g_font_loaded = 0;
    return -1;
}

// INTEGER API wrapper for REAL text rendering
int draw_text(const char* text, int x, int y, int size) {
    if (!text || strlen(text) == 0) return -1;
    
    if (!g_font_loaded) {
        printf("🔤 Font not loaded, using rectangle fallback for: %s\n", text);
        // Fallback to rectangles (same as original int version)
        int char_width = (size * 6) / 10;
        int char_spacing = char_width + 2;
        
        int len = strlen(text);
        for (int i = 0; i < len; i++) {
            if (text[i] >= 32 && text[i] <= 126) {
                draw_filled_rectangle(x + i * char_spacing, y, char_width, size);
            }
        }
        return 0;
    }
    
    printf("🔤 Rendering REAL TTF text: '%s' at (%d, %d) size %d\n", text, x, y, size);
    
    // Convert integers to floats for internal TTF rendering
    float fx = (float)x;
    float fy = (float)y; 
    float fsize = (float)size;
    
    // Calculate scale for requested size
    float scale = stbtt_ScaleForPixelHeight(&g_font, fsize * 1.15f);
    
    int ascent, descent, line_gap;
    stbtt_GetFontVMetrics(&g_font, &ascent, &descent, &line_gap);
    
    float baseline = fy + ascent * scale;
    float current_x = fx;
    
    // Render each character with professional quality
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
                // Render bitmap with professional anti-aliasing
                float char_x = current_x + left_bearing * scale;
                float char_y = baseline + y0;
                
                glEnable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                glBegin(GL_QUADS);
                for (int by = 0; by < bitmap_height; by++) {
                    for (int bx = 0; bx < bitmap_width; bx++) {
                        unsigned char alpha = bitmap[by * bitmap_width + bx];
                        
                        if (alpha > 8) {
                            float px = char_x + bx;
                            float py = char_y + by;
                            
                            // Professional alpha blending
                            float alpha_f = (float)alpha / 255.0f;
                            alpha_f = alpha_f * alpha_f; // Gamma correction
                            glColor4f(1.0f, 1.0f, 1.0f, alpha_f);
                            
                            glVertex2f(px, py);
                            glVertex2f(px + 1, py);
                            glVertex2f(px + 1, py + 1);
                            glVertex2f(px, py + 1);
                        }
                    }
                }
                glEnd();
                
                glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
                stbtt_FreeBitmap(bitmap, NULL);
            }
        }
        
        // Add letter spacing for modern UI
        current_x += (advance_width * scale) + 0.5f;
    }
    
    return 0;
}

// INTEGER API for text measurements (with TTF accuracy)
int get_text_width(const char* text, int size) {
    if (!text) return 0;
    
    if (!g_font_loaded) {
        // Fallback calculation
        int char_width = (size * 6) / 10;
        int char_spacing = char_width + 2;
        int len = strlen(text);
        return len > 0 ? (len - 1) * char_spacing + char_width : 0;
    }
    
    // Real calculation with stb_truetype
    float scale = stbtt_ScaleForPixelHeight(&g_font, (float)size);
    float total_width = 0.0f;
    
    for (const char* p = text; *p; p++) {
        int advance_width, left_bearing;
        stbtt_GetCodepointHMetrics(&g_font, *p, &advance_width, &left_bearing);
        total_width += advance_width * scale;
    }
    
    return (int)(total_width + 0.5f); // Round to nearest integer
}

int get_text_height(const char* text, int size) {
    (void)text; // Text content doesn't affect height in most fonts
    return size; // Return the requested size as height
}

// All other functions remain the same as rendering_primitives_int.c
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

int set_color(int r, int g, int b, int a) {
    // Convert 0-255 range to 0.0-1.0 range
    float rf = (r < 0) ? 0.0f : (r > 255) ? 1.0f : r / 255.0f;
    float gf = (g < 0) ? 0.0f : (g > 255) ? 1.0f : g / 255.0f;
    float bf = (b < 0) ? 0.0f : (b > 255) ? 1.0f : b / 255.0f;
    float af = (a < 0) ? 0.0f : (a > 255) ? 1.0f : a / 255.0f;
    
    glColor4f(rf, gf, bf, af);
    return 0;
}

int draw_rectangle(int x, int y, int width, int height) {
    glBegin(GL_LINE_LOOP);
    glVertex2i(x, y);
    glVertex2i(x + width, y);
    glVertex2i(x + width, y + height);
    glVertex2i(x, y + height);
    glEnd();
    return 0;
}

int draw_filled_rectangle(int x, int y, int width, int height) {
    glBegin(GL_QUADS);
    glVertex2i(x, y);
    glVertex2i(x + width, y);
    glVertex2i(x + width, y + height);
    glVertex2i(x, y + height);
    glEnd();
    return 0;
}

int draw_circle(int x, int y, int radius, int segments) {
    if (segments < 3) segments = 16;
    if (segments > 360) segments = 360;
    
    glBegin(GL_LINE_LOOP);
    for (int i = 0; i < segments; i++) {
        float angle = 2.0f * M_PI * i / segments;
        int px = x + (int)(radius * cosf(angle));
        int py = y + (int)(radius * sinf(angle));
        glVertex2i(px, py);
    }
    glEnd();
    return 0;
}

int draw_filled_circle(int x, int y, int radius, int segments) {
    if (segments < 3) segments = 16;
    if (segments > 360) segments = 360;
    
    glBegin(GL_TRIANGLE_FAN);
    glVertex2i(x, y);
    for (int i = 0; i <= segments; i++) {
        float angle = 2.0f * M_PI * i / segments;
        int px = x + (int)(radius * cosf(angle));
        int py = y + (int)(radius * sinf(angle));
        glVertex2i(px, py);
    }
    glEnd();
    return 0;
}

int draw_line(int x1, int y1, int x2, int y2, int thickness) {
    glLineWidth((float)thickness);
    glBegin(GL_LINES);
    glVertex2i(x1, y1);
    glVertex2i(x2, y2);
    glEnd();
    glLineWidth(1.0f);
    return 0;
}

int poll_events(void) {
    if (!g_window) return -1;
    glfwPollEvents();
    return 0;
}

int get_mouse_x(void) {
    return g_mouse_x;
}

int get_mouse_y(void) {
    return g_mouse_y;
}

int get_mouse_button_state(int button) {
    if (button < 0 || button >= 8) return 0;
    return g_mouse_buttons[button];
}

int get_key_state(int key_code) {
    if (key_code < 0 || key_code >= 512) return 0;
    return g_keys[key_code];
}

int should_close_window(void) {
    return g_should_close || (g_window && glfwWindowShouldClose(g_window));
}

int set_window_size(int width, int height) {
    if (!g_window || width <= 0 || height <= 0) return -1;
    glfwSetWindowSize(g_window, width, height);
    return 0;
}

int get_window_width(void) {
    return g_window_width;
}

int get_window_height(void) {
    return g_window_height;
}

// === TEXT INPUT FUNCTIONS ===

/**
 * Get the current text input buffer
 * Returns pointer to null-terminated string
 */
const char* get_input_text(void) {
    return g_input_buffer;
}

/**
 * Check if there's new input since last call
 * Returns: 1 if new input available, 0 otherwise
 */
int has_new_input(void) {
    int result = g_has_new_input;
    g_has_new_input = 0; // Reset flag after reading
    return result;
}

/**
 * Clear the input buffer
 */
int clear_input_buffer(void) {
    g_input_buffer[0] = '\0';
    g_input_buffer_pos = 0;
    g_has_new_input = 0;
    return 0;
}

/**
 * Get length of current input text
 */
int get_input_length(void) {
    return g_input_buffer_pos;
}

// === SYSTEM COLOR DETECTION FUNCTIONS ===

/**
 * Detect if system is using dark mode
 * Returns: 1 = dark mode, 0 = light mode, -1 = unknown
 */
int get_system_dark_mode(void) {
#ifdef __linux__
    // Check GNOME/GTK dark theme preference
    FILE* fp = popen("gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null", "r");
    if (fp) {
        char theme[256];
        if (fgets(theme, sizeof(theme), fp)) {
            pclose(fp);
            // Check for dark theme indicators
            if (strstr(theme, "dark") || strstr(theme, "Dark") || 
                strstr(theme, "Adwaita-dark") || strstr(theme, "Yaru-dark")) {
                return 1;
            }
            return 0;
        }
        pclose(fp);
    }
    
    // Fallback: Check GTK settings file
    char* home = getenv("HOME");
    if (home) {
        char settings_path[512];
        snprintf(settings_path, sizeof(settings_path), "%s/.config/gtk-3.0/settings.ini", home);
        
        FILE* settings = fopen(settings_path, "r");
        if (settings) {
            char line[256];
            while (fgets(line, sizeof(line), settings)) {
                if (strstr(line, "gtk-application-prefer-dark-theme") && strstr(line, "true")) {
                    fclose(settings);
                    return 1;
                }
            }
            fclose(settings);
            return 0;
        }
    }
    
    // Last resort: Check environment variables
    char* theme = getenv("GTK_THEME");
    if (theme && (strstr(theme, "dark") || strstr(theme, "Dark"))) {
        return 1;
    }
    
#elif defined(__APPLE__)
    // macOS dark mode detection
    FILE* fp = popen("defaults read -g AppleInterfaceStyle 2>/dev/null", "r");
    if (fp) {
        char result[64];
        if (fgets(result, sizeof(result), fp)) {
            pclose(fp);
            if (strstr(result, "Dark")) {
                return 1;
            }
        } else {
            pclose(fp);
            return 0; // Command failed = light mode
        }
    }
    
#elif defined(_WIN32)
    // Windows dark mode detection via registry
    // This would require additional Windows API calls
    // For now, return unknown
#endif
    
    return -1; // Unknown
}

/**
 * Get system accent color (returns packed RGBA as single int)
 * Returns: 0xRRGGBBAA format, or -1 if unknown
 */
int get_system_accent_color(void) {
#ifdef __linux__
    // Try to get GNOME accent color
    FILE* fp = popen("gsettings get org.gnome.desktop.interface accent-color 2>/dev/null", "r");
    if (fp) {
        char color[64];
        if (fgets(color, sizeof(color), fp)) {
            pclose(fp);
            // Parse color string (usually like 'blue', 'red', etc.)
            if (strstr(color, "blue")) return 0x0078D4FF;     // Windows blue
            if (strstr(color, "green")) return 0x107C10FF;    // Windows green  
            if (strstr(color, "red")) return 0xD13438FF;      // Windows red
            if (strstr(color, "orange")) return 0xFF8C00FF;   // Windows orange
            if (strstr(color, "purple")) return 0x881798FF;   // Windows purple
        }
        pclose(fp);
    }
    
    // Fallback to Ubuntu/Linux default blue
    return 0xE95420FF; // Ubuntu orange
    
#elif defined(__APPLE__)
    // macOS accent color detection
    FILE* fp = popen("defaults read -g AppleAccentColor 2>/dev/null", "r");
    if (fp) {
        char result[64];
        if (fgets(result, sizeof(result), fp)) {
            int accent = atoi(result);
            pclose(fp);
            
            // macOS accent color mapping
            switch (accent) {
                case 0: return 0xFF3B30FF; // Red
                case 1: return 0xFF9500FF; // Orange  
                case 2: return 0xFFCC02FF; // Yellow
                case 3: return 0x30D158FF; // Green
                case 4: return 0x007AFF FF; // Blue (default)
                case 5: return 0xAF52DEFF; // Purple
                case 6: return 0xFF2D92FF; // Pink
                default: return 0x007AFFFF; // Blue
            }
        }
        pclose(fp);
    }
    
    // Fallback to macOS default blue
    return 0x007AFFFF;
    
#elif defined(_WIN32)
    // Windows accent color would require registry access
    // For now, return Windows default blue
    return 0x0078D4FF;
#endif
    
    return -1; // Unknown
}

/**
 * Get system background color for windows
 * Returns: 0xRRGGBBAA format, or -1 if unknown
 */
int get_system_window_color(void) {
    int dark_mode = get_system_dark_mode();
    
    if (dark_mode == 1) {
        // Dark mode colors
#ifdef __APPLE__
        return 0x1E1E1EFF; // macOS dark background
#elif defined(_WIN32) 
        return 0x202020FF; // Windows dark background
#else
        return 0x2D2D2DFF; // Linux dark background
#endif
    } else if (dark_mode == 0) {
        // Light mode colors
#ifdef __APPLE__
        return 0xF5F5F5FF; // macOS light background
#elif defined(_WIN32)
        return 0xF0F0F0FF; // Windows light background  
#else
        return 0xF6F6F6FF; // Linux light background
#endif
    }
    
    // Fallback to neutral light gray
    return 0xF0F0F0FF;
}

/**
 * Get system text color
 * Returns: 0xRRGGBBAA format, or -1 if unknown
 */
int get_system_text_color(void) {
    int dark_mode = get_system_dark_mode();
    
    if (dark_mode == 1) {
        // Dark mode text (light text)
        return 0xFFFFFFFF; // White text
    } else if (dark_mode == 0) {
        // Light mode text (dark text)
        return 0x000000FF; // Black text
    }
    
    // Fallback to black text
    return 0x000000FF;
}
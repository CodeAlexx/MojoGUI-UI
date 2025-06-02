/**
 * Integer-Only Rendering Primitives for Mojo GUI
 * 
 * Provides OpenGL drawing functions using only integer parameters
 * to avoid Mojo FFI type conversion issues.
 * 
 * All colors use 0-255 range, all coordinates are pixel integers.
 */

#include "rendering_primitives_int.h"
#include <GL/gl.h>
#include <GLFW/glfw3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Simple global state for minimal interface
static GLFWwindow* g_window = NULL;
static int g_window_width = 800;
static int g_window_height = 600;
static int g_mouse_x = 0, g_mouse_y = 0;
static int g_mouse_buttons[8] = {0}; // Support up to 8 mouse buttons
static int g_keys[512] = {0}; // Support common key codes
static int g_should_close = 0;

// Font rendering (simplified - using basic OpenGL)
static unsigned int g_font_texture = 0;
static int g_font_loaded = 0;

// GLFW callbacks
static void error_callback(int error, const char* description) {
    fprintf(stderr, "GLFW Error %d: %s\n", error, description);
}

static void mouse_button_callback(GLFWwindow* window, int button, int action, int mods) {
    (void)window; (void)mods; // Suppress warnings
    if (button >= 0 && button < 8) {
        g_mouse_buttons[button] = (action == GLFW_PRESS) ? 1 : 0;
    }
}

static void cursor_position_callback(GLFWwindow* window, double xpos, double ypos) {
    (void)window; // Suppress warning
    g_mouse_x = (int)xpos;
    g_mouse_y = (int)ypos;
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    (void)window; (void)scancode; (void)mods; // Suppress warnings
    if (key >= 0 && key < 512) {
        g_keys[key] = (action == GLFW_PRESS || action == GLFW_REPEAT) ? 1 : 0;
    }
}

static void window_close_callback(GLFWwindow* window) {
    (void)window; // Suppress warning
    g_should_close = 1;
}

static void window_size_callback(GLFWwindow* window, int width, int height) {
    (void)window; // Suppress warning
    g_window_width = width;
    g_window_height = height;
    glViewport(0, 0, width, height);
    
    // Reset projection matrix
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, width, height, 0, -1, 1); // Top-left origin
    glMatrixMode(GL_MODELVIEW);
}

// Initialize OpenGL context
int initialize_gl_context(int width, int height, const char* title) {
    if (g_window != NULL) {
        return -1; // Already initialized
    }
    
    glfwSetErrorCallback(error_callback);
    
    if (!glfwInit()) {
        return -1;
    }
    
    // Create window
    g_window = glfwCreateWindow(width, height, title ? title : "Mojo GUI", NULL, NULL);
    if (!g_window) {
        glfwTerminate();
        return -1;
    }
    
    glfwMakeContextCurrent(g_window);
    glfwSwapInterval(1); // Enable vsync
    
    // Set callbacks
    glfwSetMouseButtonCallback(g_window, mouse_button_callback);
    glfwSetCursorPosCallback(g_window, cursor_position_callback);
    glfwSetKeyCallback(g_window, key_callback);
    glfwSetWindowCloseCallback(g_window, window_close_callback);
    glfwSetWindowSizeCallback(g_window, window_size_callback);
    
    g_window_width = width;
    g_window_height = height;
    
    // Initialize OpenGL
    glViewport(0, 0, width, height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, width, height, 0, -1, 1); // Top-left origin
    glMatrixMode(GL_MODELVIEW);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    return 0;
}

int cleanup_gl(void) {
    if (g_font_texture != 0) {
        glDeleteTextures(1, &g_font_texture);
        g_font_texture = 0;
    }
    
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
    glVertex2i(x, y); // Center
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
    glLineWidth(1.0f); // Reset
    return 0;
}

// Simplified text rendering (placeholder - would need proper font system)
int load_default_font(void) {
    // For now, mark as loaded but don't actually load anything
    // In a full implementation, this would load a bitmap font or use FreeType
    g_font_loaded = 1;
    return 0;
}

int draw_text(const char* text, int x, int y, int size) {
    if (!g_font_loaded || !text) return -1;
    
    // Simplified: draw text as rectangles (placeholder)
    // In a real implementation, this would render actual glyphs
    int char_width = (size * 6) / 10;  // Approximate character width
    int char_spacing = char_width + 2;
    
    int len = strlen(text);
    for (int i = 0; i < len; i++) {
        if (text[i] >= 32 && text[i] <= 126) { // Printable ASCII
            draw_filled_rectangle(x + i * char_spacing, y, char_width, size);
        }
    }
    
    return 0;
}

int get_text_width(const char* text, int size) {
    if (!text) return 0;
    
    int char_width = (size * 6) / 10;
    int char_spacing = char_width + 2;
    
    int len = strlen(text);
    return len > 0 ? (len - 1) * char_spacing + char_width : 0;
}

int get_text_height(const char* text, int size) {
    (void)text; // Text doesn't affect height in this simple implementation
    return size;
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
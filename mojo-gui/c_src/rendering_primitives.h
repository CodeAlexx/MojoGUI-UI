#ifndef RENDERING_PRIMITIVES_H
#define RENDERING_PRIMITIVES_H

#ifdef __cplusplus
extern "C" {
#endif

// Basic types for Mojo FFI compatibility
typedef struct {
    float r, g, b, a;
} Color;

typedef struct {
    float x, y;
} Point;

typedef struct {
    float width, height;
} Size;

typedef struct {
    float x, y, width, height;
} Rect;

// Initialization and cleanup
int initialize_gl_context(int width, int height, const char* title);
int cleanup_gl(void);

// Frame management
int frame_begin(void);
int frame_end(void);

// Basic drawing primitives
int set_color(float r, float g, float b, float a);
int draw_rectangle(float x, float y, float width, float height);
int draw_filled_rectangle(float x, float y, float width, float height);
int draw_circle(float x, float y, float radius, int segments);
int draw_filled_circle(float x, float y, float radius, int segments);
int draw_line(float x1, float y1, float x2, float y2, float thickness);

// Text rendering (minimal interface)
int load_default_font(void);
int draw_text(const char* text, float x, float y, float size);
int get_text_size(const char* text, float size, float* width, float* height);

// Event handling (polling interface for simplicity)
int poll_events(void);
int get_mouse_position(int* x, int* y);
int get_mouse_button_state(int button); // 0=not pressed, 1=pressed
int get_key_state(int key_code); // 0=not pressed, 1=pressed
int should_close_window(void);

// Window management
int set_window_size(int width, int height);
int get_window_size(int* width, int* height);

#ifdef __cplusplus
}
#endif

#endif // RENDERING_PRIMITIVES_H
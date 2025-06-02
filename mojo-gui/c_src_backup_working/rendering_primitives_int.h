#ifndef RENDERING_PRIMITIVES_INT_H
#define RENDERING_PRIMITIVES_INT_H

#ifdef __cplusplus
extern "C" {
#endif

// INTEGER-ONLY FFI Interface for Mojo
// All coordinates and colors use integers to avoid FFI issues
// Colors: 0-255 range (instead of 0.0-1.0)
// Positions: pixel coordinates as integers
// Sizes: pixel dimensions as integers

// Initialization and cleanup
int initialize_gl_context(int width, int height, const char* title);
int cleanup_gl(void);

// Frame management
int frame_begin(void);
int frame_end(void);

// Basic drawing primitives (integer coordinates and colors)
int set_color(int r, int g, int b, int a);                    // RGBA 0-255
int draw_rectangle(int x, int y, int width, int height);      // Pixel coordinates
int draw_filled_rectangle(int x, int y, int width, int height);
int draw_circle(int x, int y, int radius, int segments);      // Pixel coordinates
int draw_filled_circle(int x, int y, int radius, int segments);
int draw_line(int x1, int y1, int x2, int y2, int thickness); // Pixel coordinates

// Text rendering (integer-only interface)
int load_default_font(void);
int draw_text(const char* text, int x, int y, int size);      // Pixel coordinates
int get_text_width(const char* text, int size);               // Returns pixel width
int get_text_height(const char* text, int size);              // Returns pixel height

// Event handling (integer coordinates)
int poll_events(void);
int get_mouse_x(void);                                         // Returns pixel X
int get_mouse_y(void);                                         // Returns pixel Y  
int get_mouse_button_state(int button);                       // 0=not pressed, 1=pressed
int get_key_state(int key_code);                             // 0=not pressed, 1=pressed
int should_close_window(void);

// Window management
int set_window_size(int width, int height);
int get_window_width(void);
int get_window_height(void);

#ifdef __cplusplus
}
#endif

#endif // RENDERING_PRIMITIVES_INT_H
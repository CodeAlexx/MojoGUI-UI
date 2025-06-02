# Makefile for minimal rendering primitives library

CC = gcc
CFLAGS = -Wall -Wextra -fPIC -O2 -std=c99
LDFLAGS = -shared
LDLIBS = -lglfw -lGL -lm

TARGET = librendering_primitives.so
TARGET_INT = librendering_primitives_int.so
TARGET_INT_FONTS = librendering_primitives_int_with_fonts.so
SOURCES = rendering_primitives.c
SOURCES_INT = rendering_primitives_int.c
SOURCES_INT_FONTS = rendering_primitives_int_with_fonts.c
OBJECTS = $(SOURCES:.c=.o)
OBJECTS_INT = $(SOURCES_INT:.c=.o)
OBJECTS_INT_FONTS = $(SOURCES_INT_FONTS:.c=.o)

.PHONY: all clean test int int_fonts

all: $(TARGET)

int: $(TARGET_INT)

int_fonts: $(TARGET_INT_FONTS)

$(TARGET_INT): $(OBJECTS_INT)
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)
	@echo "Built integer-only $(TARGET_INT) successfully!"

$(TARGET_INT_FONTS): $(OBJECTS_INT_FONTS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)
	@echo "Built integer API with TTF fonts $(TARGET_INT_FONTS) successfully!"

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)
	@echo "Built $(TARGET) successfully!"

%.o: %.c rendering_primitives.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(OBJECTS_INT) $(OBJECTS_INT_FONTS) $(TARGET) $(TARGET_INT) $(TARGET_INT_FONTS)

test: $(TARGET)
	@echo "Testing library symbols..."
	nm -D $(TARGET) | grep -E "(initialize_gl|draw_|set_color)" | sort

test_run: $(TARGET) test_primitives
	@echo "Running C test program..."
	LD_LIBRARY_PATH=. ./test_primitives

test_primitives: test_primitives.c $(TARGET)
	$(CC) $(CFLAGS) -o test_primitives test_primitives.c -L. -lrendering_primitives $(LDLIBS)

test_int: test_int.c $(TARGET_INT)
	$(CC) $(CFLAGS) -o test_int test_int.c -L. -lrendering_primitives_int $(LDLIBS)

test_int_run: $(TARGET_INT) test_int
	@echo "Running integer-only test program..."
	LD_LIBRARY_PATH=. ./test_int

test_int_fonts: test_int_fonts.c $(TARGET_INT_FONTS)
	$(CC) $(CFLAGS) -o test_int_fonts test_int_fonts.c -L. -lrendering_primitives_int_with_fonts $(LDLIBS)

test_int_fonts_run: $(TARGET_INT_FONTS) test_int_fonts
	@echo "Running integer API with TTF fonts test..."
	LD_LIBRARY_PATH=. ./test_int_fonts

install-deps:
	@echo "Installing dependencies..."
	sudo apt-get update
	sudo apt-get install -y libglfw3-dev libgl1-mesa-dev
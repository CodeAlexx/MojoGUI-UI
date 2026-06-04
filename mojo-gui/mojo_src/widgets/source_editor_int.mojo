"""
Integer-Only Source Code Editor Widget Implementation
Professional code editor with syntax highlighting, line numbers, and advanced features.
"""

from sys.ffi import DLHandle
from memory import UnsafePointer
from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .scrollbar_int import ScrollBarInt

# Editor modes
comptime MODE_NORMAL = 0
comptime MODE_INSERT = 1
comptime MODE_VISUAL = 2
comptime MODE_VISUAL_LINE = 3
comptime MODE_VISUAL_BLOCK = 4

# Language modes for syntax highlighting
comptime LANG_PLAIN = 0
comptime LANG_MOJO = 1
comptime LANG_PYTHON = 2
comptime LANG_C = 3
comptime LANG_CPP = 4
comptime LANG_JAVASCRIPT = 5
comptime LANG_HTML = 6
comptime LANG_CSS = 7
comptime LANG_JSON = 8
comptime LANG_XML = 9
comptime LANG_MARKDOWN = 10

# Token types for syntax highlighting
comptime TOKEN_NORMAL = 0
comptime TOKEN_KEYWORD = 1
comptime TOKEN_STRING = 2
comptime TOKEN_NUMBER = 3
comptime TOKEN_COMMENT = 4
comptime TOKEN_FUNCTION = 5
comptime TOKEN_TYPE = 6
comptime TOKEN_OPERATOR = 7
comptime TOKEN_BRACKET = 8
comptime TOKEN_PREPROCESSOR = 9

struct TextPosition(Copyable, Movable):
    """Position in text (line and column)."""
    var line: Int32
    var column: Int32

    fn __init__(out self, line: Int32 = 0, column: Int32 = 0):
        self.line = line
        self.column = column

    fn equals(self, other: TextPosition) -> Bool:
        return self.line == other.line and self.column == other.column

    fn is_before(self, other: TextPosition) -> Bool:
        return self.line < other.line or (self.line == other.line and self.column < other.column)

struct TextSelection(Copyable, Movable):
    """Text selection range."""
    var start: TextPosition
    var end: TextPosition
    var is_active: Bool

    fn __init__(out self):
        self.start = TextPosition()
        self.end = TextPosition()
        self.is_active = False

    fn clear(mut self):
        self.is_active = False

    fn normalize(self) -> Tuple[TextPosition, TextPosition]:
        """Return normalized start and end (start always before end)."""
        if self.start.is_before(self.end):
            return Tuple[TextPosition, TextPosition](self.start, self.end)
        else:
            return Tuple[TextPosition, TextPosition](self.end, self.start)

struct SyntaxToken(Copyable, Movable):
    """Syntax highlighting token."""
    var start_col: Int32
    var end_col: Int32
    var token_type: Int32

    fn __init__(out self, start_col: Int32, end_col: Int32, token_type: Int32):
        self.start_col = start_col
        self.end_col = end_col
        self.token_type = token_type

struct EditorLine(Copyable, Movable):
    """Single line in the editor."""
    var text: String
    var tokens: List[SyntaxToken]
    var is_folded: Bool
    var fold_level: Int32
    var bookmark: Bool
    var breakpoint: Bool

    fn __init__(out self, text: String = ""):
        self.text = text
        self.tokens = List[SyntaxToken]()
        self.is_folded = False
        self.fold_level = 0
        self.bookmark = False
        self.breakpoint = False

struct UndoOperation(Copyable, Movable):
    """Undo/redo operation."""
    var position: TextPosition
    var text_removed: String
    var text_added: String
    var selection_before: TextSelection
    var selection_after: TextSelection

    fn __init__(out self):
        self.position = TextPosition()
        self.text_removed = ""
        self.text_added = ""
        self.selection_before = TextSelection()
        self.selection_after = TextSelection()

struct SourceEditorInt(Copyable, Movable):
    """Professional source code editor with syntax highlighting."""

    # Inlined BaseWidgetInt fields (struct inheritance is not supported).
    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    var background_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32

    # Document
    var lines: List[EditorLine]
    var language_mode: Int32
    var tab_size: Int32
    var use_spaces: Bool
    var auto_indent: Bool
    var show_whitespace: Bool
    var word_wrap: Bool
    var readonly: Bool
    
    # Display
    var font_size: Int32
    var line_height: Int32
    var char_width: Int32
    var gutter_width: Int32
    var show_line_numbers: Bool
    var show_fold_gutter: Bool
    var highlight_current_line: Bool
    var show_indent_guides: Bool
    
    # Viewport
    var scroll_x: Int32
    var scroll_y: Int32
    var visible_lines: Int32
    var visible_columns: Int32
    var h_scrollbar: ScrollBarInt
    var v_scrollbar: ScrollBarInt
    
    # Cursor and selection
    var cursor: TextPosition
    var selection: TextSelection
    var mode: Int32
    var cursor_blink_time: Int32
    var bracket_match_pos: TextPosition
    var multiple_cursors: List[TextPosition]
    
    # Undo/Redo
    var undo_stack: List[UndoOperation]
    var redo_stack: List[UndoOperation]
    var max_undo_levels: Int32
    var current_operation: UndoOperation
    
    # Find/Replace
    var find_text: String
    var replace_text: String
    var find_case_sensitive: Bool
    var find_whole_word: Bool
    var find_regex: Bool
    var find_results: List[TextPosition]
    var current_find_index: Int32
    
    # Colors
    var bg_color: ColorInt
    var text_color: ColorInt
    var line_number_color: ColorInt
    var gutter_bg_color: ColorInt
    var selection_color: ColorInt
    var current_line_color: ColorInt
    var bracket_match_color: ColorInt
    var indent_guide_color: ColorInt
    
    # Syntax colors
    var keyword_color: ColorInt
    var string_color: ColorInt
    var number_color: ColorInt
    var comment_color: ColorInt
    var function_color: ColorInt
    var type_color: ColorInt
    var operator_color: ColorInt
    var preprocessor_color: ColorInt
    
    # Interaction
    var is_focused: Bool
    var is_dragging: Bool
    var drag_start_pos: TextPosition
    var hover_line: Int32
    var hover_gutter: Bool
    
    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32):
        # Inlined BaseWidgetInt.__init__
        self.bounds = RectInt(x, y, width, height)
        self.visible = True
        self.enabled = True
        self.background_color = ColorInt(230, 230, 230, 255)
        self.border_color = ColorInt(128, 128, 128, 255)
        self.border_width = 1

        # Initialize document
        self.lines = List[EditorLine]()
        self.lines.append(EditorLine(""))
        self.language_mode = LANG_PLAIN
        self.tab_size = 4
        self.use_spaces = True
        self.auto_indent = True
        self.show_whitespace = False
        self.word_wrap = False
        self.readonly = False
        
        # Display settings
        self.font_size = 13
        self.line_height = 18
        self.char_width = 8
        self.gutter_width = 60
        self.show_line_numbers = True
        self.show_fold_gutter = True
        self.highlight_current_line = True
        self.show_indent_guides = True
        
        # Viewport
        self.scroll_x = 0
        self.scroll_y = 0
        self.visible_lines = height // self.line_height
        self.visible_columns = (width - self.gutter_width) // self.char_width
        
        # Initialize scrollbars
        self.h_scrollbar = ScrollBarInt(x, y + height - 15, width - 15, 15, True)
        self.v_scrollbar = ScrollBarInt(x + width - 15, y, 15, height - 15, False)
        
        # Cursor and selection
        self.cursor = TextPosition(0, 0)
        self.selection = TextSelection()
        self.mode = MODE_INSERT
        self.cursor_blink_time = 0
        self.bracket_match_pos = TextPosition(-1, -1)
        self.multiple_cursors = List[TextPosition]()
        
        # Undo/Redo
        self.undo_stack = List[UndoOperation]()
        self.redo_stack = List[UndoOperation]()
        self.max_undo_levels = 1000
        self.current_operation = UndoOperation()
        
        # Find/Replace
        self.find_text = ""
        self.replace_text = ""
        self.find_case_sensitive = False
        self.find_whole_word = False
        self.find_regex = False
        self.find_results = List[TextPosition]()
        self.current_find_index = -1
        
        # Colors - Professional dark theme
        self.bg_color = ColorInt(30, 30, 30, 255)
        self.text_color = ColorInt(212, 212, 212, 255)
        self.line_number_color = ColorInt(133, 133, 133, 255)
        self.gutter_bg_color = ColorInt(37, 37, 38, 255)
        self.selection_color = ColorInt(38, 79, 120, 200)
        self.current_line_color = ColorInt(42, 42, 42, 255)
        self.bracket_match_color = ColorInt(100, 100, 100, 128)
        self.indent_guide_color = ColorInt(60, 60, 60, 255)
        
        # Syntax highlighting colors
        self.keyword_color = ColorInt(86, 156, 214, 255)   # Blue
        self.string_color = ColorInt(206, 145, 120, 255)   # Orange
        self.number_color = ColorInt(181, 206, 168, 255)   # Light green
        self.comment_color = ColorInt(106, 153, 85, 255)   # Green
        self.function_color = ColorInt(220, 220, 170, 255) # Yellow
        self.type_color = ColorInt(78, 201, 176, 255)      # Cyan
        self.operator_color = ColorInt(212, 212, 212, 255) # White
        self.preprocessor_color = ColorInt(155, 155, 155, 255) # Gray
        
        # Interaction
        self.is_focused = False
        self.is_dragging = False
        self.drag_start_pos = TextPosition()
        self.hover_line = -1
        self.hover_gutter = False
        
        # Override base widget appearance
        self.background_color = self.bg_color
        self.border_color = ColorInt(60, 60, 60, 255)
        self.border_width = 1

    # Inlined BaseWidgetInt methods (struct inheritance is not supported).
    fn get_bounds(self) -> RectInt:
        return self.bounds

    fn set_bounds(mut self, bounds: RectInt):
        self.bounds = bounds

    fn is_visible(self) -> Bool:
        return self.visible

    fn set_visible(mut self, visible: Bool):
        self.visible = visible

    fn is_enabled(self) -> Bool:
        return self.enabled

    fn set_enabled(mut self, enabled: Bool):
        self.enabled = enabled

    fn contains_point(self, point: PointInt) -> Bool:
        return self.bounds.contains(point)

    fn render_background(self, ctx: RenderingContextInt):
        if not self.visible:
            return
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                          self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y,
                                      self.bounds.width, self.bounds.height)
        if self.border_width > 0:
            _ = ctx.set_color(self.border_color.r, self.border_color.g,
                              self.border_color.b, self.border_color.a)
            _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y,
                                   self.bounds.width, self.bounds.height)

    fn set_text(mut self, text: String):
        """Set the entire document text."""
        self.lines.clear()
        
        if len(text) == 0:
            self.lines.append(EditorLine(""))
            return
        
        # Split into lines (simplified)
        var current_line = String("")
        var text_bytes = text.as_bytes()
        for i in range(len(text_bytes)):
            var ch = Int(text_bytes[i])
            if ch == ord("\n"):
                self.lines.append(EditorLine(current_line))
                current_line = String("")
            else:
                current_line += chr(ch)

        # Add last line
        self.lines.append(EditorLine(current_line))
        
        # Trigger syntax highlighting
        self.highlight_all_lines()
        
        # Reset cursor
        self.cursor = TextPosition(0, 0)
        self.selection.clear()
    
    fn get_text(self) -> String:
        """Get the entire document text."""
        var result = ""
        for i in range(len(self.lines)):
            if i > 0:
                result += "\n"
            result += self.lines[i].text
        return result
    
    fn set_language_mode(mut self, mode: Int32):
        """Set syntax highlighting language mode."""
        self.language_mode = mode
        self.highlight_all_lines()

    fn highlight_line(mut self, line_idx: Int32):
        """Apply syntax highlighting to a single line."""
        if line_idx < 0 or line_idx >= len(self.lines):
            return

        var line = self.lines[Int(line_idx)]
        line.tokens.clear()

        # Simple tokenization based on language mode
        if self.language_mode == LANG_PLAIN:
            self.lines[Int(line_idx)] = line
            return

        # Get keywords for language
        var keywords = self.get_keywords_for_language()

        # Simplified tokenization - just highlights keywords, strings, comments, numbers
        var text = line.text
        var bytes = text.as_bytes()
        var n = len(bytes)
        var i = 0

        var SPACE = ord(" ")
        var TAB = ord("\t")
        var DQUOTE = ord("\"")
        var SQUOTE = ord("'")
        var BSLASH = ord("\\")
        var DOT = ord(".")
        var UNDERSCORE = ord("_")
        var LPAREN = ord("(")
        var ZERO = ord("0")
        var NINE = ord("9")
        var UA = ord("A")
        var UZ = ord("Z")
        var LA = ord("a")
        var LZ = ord("z")

        while i < n:
            var c = Int(bytes[i])

            # Skip whitespace
            if c == SPACE or c == TAB:
                i += 1
                continue

            # Comments
            if self.check_comment_start(text, Int32(i)):
                line.tokens.append(SyntaxToken(Int32(i), Int32(n), TOKEN_COMMENT))
                break

            # Strings
            if c == DQUOTE or c == SQUOTE:
                var quote = c
                var end = i + 1
                while end < n and Int(bytes[end]) != quote:
                    if Int(bytes[end]) == BSLASH and end + 1 < n:
                        end += 2
                    else:
                        end += 1
                if end < n:
                    end += 1
                line.tokens.append(SyntaxToken(Int32(i), Int32(end), TOKEN_STRING))
                i = end
                continue

            # Numbers
            if c >= ZERO and c <= NINE:
                var end = i + 1
                while end < n:
                    var d = Int(bytes[end])
                    if (d >= ZERO and d <= NINE) or d == DOT:
                        end += 1
                    else:
                        break
                line.tokens.append(SyntaxToken(Int32(i), Int32(end), TOKEN_NUMBER))
                i = end
                continue

            # Identifiers and keywords
            if (c >= UA and c <= UZ) or (c >= LA and c <= LZ) or c == UNDERSCORE:
                var end = i + 1
                while end < n:
                    var d = Int(bytes[end])
                    if (d >= UA and d <= UZ) or (d >= LA and d <= LZ) or (d >= ZERO and d <= NINE) or d == UNDERSCORE:
                        end += 1
                    else:
                        break

                var word = String(text)[i:end]
                var token_type = TOKEN_NORMAL

                if self.word_in_list(word, keywords):
                    token_type = TOKEN_KEYWORD
                elif self.is_type_name(word):
                    token_type = TOKEN_TYPE
                elif end < n and Int(bytes[end]) == LPAREN:
                    token_type = TOKEN_FUNCTION

                line.tokens.append(SyntaxToken(Int32(i), Int32(end), token_type))
                i = end
                continue

            # Operators and brackets
            if self.is_operator_byte(c):
                line.tokens.append(SyntaxToken(Int32(i), Int32(i + 1), TOKEN_OPERATOR))
            elif self.is_bracket_byte(c):
                line.tokens.append(SyntaxToken(Int32(i), Int32(i + 1), TOKEN_BRACKET))

            i += 1

        self.lines[Int(line_idx)] = line

    fn word_in_list(self, word: String, words: List[String]) -> Bool:
        """Check if word is in the list."""
        for i in range(len(words)):
            if words[i] == word:
                return True
        return False

    fn highlight_all_lines(mut self):
        """Apply syntax highlighting to all lines."""
        for i in range(len(self.lines)):
            self.highlight_line(Int32(i))
    
    fn get_keywords_for_language(self) -> List[String]:
        """Get keywords for current language mode."""
        var keywords = List[String]()

        if self.language_mode == LANG_MOJO:
            keywords = List[String]("fn", "struct", "var", "let", "if", "else", "elif", "for", "while",
                       "return", "break", "continue", "import", "from", "alias", "trait",
                       "Self", "self", "inout", "owned", "borrowed", "raises")
        elif self.language_mode == LANG_PYTHON:
            keywords = List[String]("def", "class", "if", "else", "elif", "for", "while", "return",
                       "break", "continue", "import", "from", "as", "try", "except",
                       "finally", "with", "lambda", "yield", "async", "await")
        elif self.language_mode == LANG_C or self.language_mode == LANG_CPP:
            keywords = List[String]("if", "else", "for", "while", "do", "switch", "case", "default",
                       "break", "continue", "return", "goto", "sizeof", "typedef",
                       "struct", "union", "enum", "static", "extern", "const", "volatile")

        return keywords
    
    fn is_type_name(self, word: String) -> Bool:
        """Check if word is a type name."""
        var types = List[String]("Int", "Int32", "Int64", "Float", "Float32", "Float64",
                    "Bool", "String", "void", "int", "float", "double", "char")
        for i in range(len(types)):
            if types[i] == word:
                return True
        return False

    fn is_operator_byte(self, c: Int) -> Bool:
        """Check if byte is an operator."""
        return (c == ord("+") or c == ord("-") or c == ord("*") or c == ord("/")
                or c == ord("%") or c == ord("=") or c == ord("<") or c == ord(">")
                or c == ord("!") or c == ord("&") or c == ord("|") or c == ord("^")
                or c == ord("~"))

    fn is_bracket_byte(self, c: Int) -> Bool:
        """Check if byte is a bracket."""
        return (c == ord("(") or c == ord(")") or c == ord("[") or c == ord("]")
                or c == ord("{") or c == ord("}"))

    fn check_comment_start(self, text: String, pos: Int32) -> Bool:
        """Check if position starts a comment."""
        var bytes = text.as_bytes()
        var n = len(bytes)
        if Int(pos) >= n:
            return False

        if (self.language_mode == LANG_C or self.language_mode == LANG_CPP
                or self.language_mode == LANG_MOJO):
            if Int(pos) + 1 < n:
                var c0 = Int(bytes[Int(pos)])
                var c1 = Int(bytes[Int(pos) + 1])
                return (c0 == ord("/") and (c1 == ord("/") or c1 == ord("*")))
        elif self.language_mode == LANG_PYTHON:
            return Int(bytes[Int(pos)]) == ord("#")

        return False
    
    fn handle_mouse_event(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        return True  # Simplified for demo

    fn handle_key_event(mut self, event: KeyEventInt) -> Bool:
        """Handle keyboard input."""
        return True  # Simplified for demo
    
    fn render(self, lib: DLHandle):
        """Render the editor with DLHandle."""
        if not self.visible:
            return

        # Get drawing functions
        var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
        var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
        var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
        var draw_text = lib.get_function[fn(UnsafePointer[Int8, MutExternalOrigin], Int32, Int32, Int32) -> Int32]("draw_text")

        # Background
        _ = set_color(self.bg_color.r, self.bg_color.g, self.bg_color.b, self.bg_color.a)
        _ = draw_filled_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)
        
        # Gutter
        _ = set_color(self.gutter_bg_color.r, self.gutter_bg_color.g, self.gutter_bg_color.b, self.gutter_bg_color.a)
        _ = draw_filled_rectangle(self.bounds.x, self.bounds.y, self.gutter_width, self.bounds.height)
        
        # Line numbers and text
        var text_area_x = self.bounds.x + self.gutter_width
        var start_line = self.scroll_y
        var end_line = min(self.scroll_y + self.visible_lines + 1, len(self.lines))
        
        for line_idx in range(start_line, end_line):
            var y = self.bounds.y + (line_idx - self.scroll_y) * self.line_height + 3
            
            # Line number
            _ = set_color(self.line_number_color.r, self.line_number_color.g, self.line_number_color.b, self.line_number_color.a)
            var line_num_str = String(line_idx + 1)
            var line_num_bytes = line_num_str.as_bytes()
            var line_num_ptr = line_num_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(line_num_ptr, self.bounds.x + 10, y, 11)

            # Line text with syntax highlighting
            if line_idx < len(self.lines):
                var line = self.lines[line_idx]
                var x = text_area_x + 5
                var last_end = Int32(0)

                # Render syntax highlighted tokens
                for ti in range(len(line.tokens)):
                    var token = line.tokens[ti]
                    # Render text before token
                    if token.start_col > last_end:
                        var plain_text = String(line.text)[Int(last_end):Int(token.start_col)]
                        _ = set_color(self.text_color.r, self.text_color.g, self.text_color.b, self.text_color.a)
                        var plain_bytes = plain_text.as_bytes()
                        var plain_ptr = plain_bytes.unsafe_ptr().bitcast[Int8]()
                        _ = draw_text(plain_ptr, x, y, self.font_size)
                        x += Int32(len(plain_text)) * self.char_width

                    # Render token with appropriate color
                    var token_text = String(line.text)[Int(token.start_col):Int(token.end_col)]
                    var color = self.get_token_color(token.token_type)
                    _ = set_color(color.r, color.g, color.b, color.a)
                    var token_bytes = token_text.as_bytes()
                    var token_ptr = token_bytes.unsafe_ptr().bitcast[Int8]()
                    _ = draw_text(token_ptr, x, y, self.font_size)
                    x += Int32(len(token_text)) * self.char_width

                    last_end = token.end_col

                # Render remaining text
                if Int(last_end) < len(line.text):
                    var remaining = String(line.text)[Int(last_end):]
                    _ = set_color(self.text_color.r, self.text_color.g, self.text_color.b, self.text_color.a)
                    var remaining_bytes = remaining.as_bytes()
                    var remaining_ptr = remaining_bytes.unsafe_ptr().bitcast[Int8]()
                    _ = draw_text(remaining_ptr, x, y, self.font_size)
        
        # Border
        _ = set_color(self.border_color.r, self.border_color.g, self.border_color.b, self.border_color.a)
        _ = draw_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)
    
    fn get_token_color(self, token_type: Int32) -> ColorInt:
        """Get color for token type."""
        if token_type == TOKEN_KEYWORD:
            return self.keyword_color
        elif token_type == TOKEN_STRING:
            return self.string_color
        elif token_type == TOKEN_NUMBER:
            return self.number_color
        elif token_type == TOKEN_COMMENT:
            return self.comment_color
        elif token_type == TOKEN_FUNCTION:
            return self.function_color
        elif token_type == TOKEN_TYPE:
            return self.type_color
        elif token_type == TOKEN_OPERATOR:
            return self.operator_color
        elif token_type == TOKEN_PREPROCESSOR:
            return self.preprocessor_color
        else:
            return self.text_color
    
    fn update(mut self):
        """Update editor state."""
        pass

    fn set_focus(mut self, focused: Bool):
        """Set focus state."""
        self.is_focused = focused

# Convenience functions
fn create_source_editor_int(x: Int32, y: Int32, width: Int32, height: Int32) -> SourceEditorInt:
    """Create a source code editor."""
    return SourceEditorInt(x, y, width, height)

fn create_code_viewer_int(x: Int32, y: Int32, width: Int32, height: Int32) -> SourceEditorInt:
    """Create a read-only code viewer."""
    var viewer = SourceEditorInt(x, y, width, height)
    viewer.readonly = True
    return viewer^
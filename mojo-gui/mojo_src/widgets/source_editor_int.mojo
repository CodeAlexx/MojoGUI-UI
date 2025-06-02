"""
Integer-Only Source Code Editor Widget Implementation
Professional code editor with syntax highlighting, line numbers, and advanced features.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .scrollbar_int import ScrollBarInt

# Editor modes
alias MODE_NORMAL = 0
alias MODE_INSERT = 1
alias MODE_VISUAL = 2
alias MODE_VISUAL_LINE = 3
alias MODE_VISUAL_BLOCK = 4

# Language modes for syntax highlighting
alias LANG_PLAIN = 0
alias LANG_MOJO = 1
alias LANG_PYTHON = 2
alias LANG_C = 3
alias LANG_CPP = 4
alias LANG_JAVASCRIPT = 5
alias LANG_HTML = 6
alias LANG_CSS = 7
alias LANG_JSON = 8
alias LANG_XML = 9
alias LANG_MARKDOWN = 10

# Token types for syntax highlighting
alias TOKEN_NORMAL = 0
alias TOKEN_KEYWORD = 1
alias TOKEN_STRING = 2
alias TOKEN_NUMBER = 3
alias TOKEN_COMMENT = 4
alias TOKEN_FUNCTION = 5
alias TOKEN_TYPE = 6
alias TOKEN_OPERATOR = 7
alias TOKEN_BRACKET = 8
alias TOKEN_PREPROCESSOR = 9

struct TextPosition:
    """Position in text (line and column)."""
    var line: Int32
    var column: Int32
    
    fn __init__(inout self, line: Int32 = 0, column: Int32 = 0):
        self.line = line
        self.column = column
    
    fn equals(self, other: TextPosition) -> Bool:
        return self.line == other.line and self.column == other.column
    
    fn is_before(self, other: TextPosition) -> Bool:
        return self.line < other.line or (self.line == other.line and self.column < other.column)

struct TextSelection:
    """Text selection range."""
    var start: TextPosition
    var end: TextPosition
    var is_active: Bool
    
    fn __init__(inout self):
        self.start = TextPosition()
        self.end = TextPosition()
        self.is_active = False
    
    fn clear(inout self):
        self.is_active = False
    
    fn normalize(self) -> (TextPosition, TextPosition):
        """Return normalized start and end (start always before end)."""
        if self.start.is_before(self.end):
            return (self.start, self.end)
        else:
            return (self.end, self.start)

struct SyntaxToken:
    """Syntax highlighting token."""
    var start_col: Int32
    var end_col: Int32
    var token_type: Int32
    
    fn __init__(inout self, start_col: Int32, end_col: Int32, token_type: Int32):
        self.start_col = start_col
        self.end_col = end_col
        self.token_type = token_type

struct EditorLine:
    """Single line in the editor."""
    var text: String
    var tokens: List[SyntaxToken]
    var is_folded: Bool
    var fold_level: Int32
    var bookmark: Bool
    var breakpoint: Bool
    
    fn __init__(inout self, text: String = ""):
        self.text = text
        self.tokens = List[SyntaxToken]()
        self.is_folded = False
        self.fold_level = 0
        self.bookmark = False
        self.breakpoint = False

struct UndoOperation:
    """Undo/redo operation."""
    var position: TextPosition
    var text_removed: String
    var text_added: String
    var selection_before: TextSelection
    var selection_after: TextSelection
    
    fn __init__(inout self):
        self.position = TextPosition()
        self.text_removed = ""
        self.text_added = ""
        self.selection_before = TextSelection()
        self.selection_after = TextSelection()

struct SourceEditorInt(BaseWidgetInt):
    """Professional source code editor with syntax highlighting."""
    
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
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.super().__init__(x, y, width, height)
        
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
    
    fn set_text(inout self, text: String):
        """Set the entire document text."""
        self.lines.clear()
        
        if len(text) == 0:
            self.lines.append(EditorLine(""))
            return
        
        # Split into lines (simplified)
        var current_line = ""
        for i in range(len(text)):
            let ch = text[i]
            if ch == '\n':
                self.lines.append(EditorLine(current_line))
                current_line = ""
            else:
                current_line += ch
        
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
    
    fn set_language_mode(inout self, mode: Int32):
        """Set syntax highlighting language mode."""
        self.language_mode = mode
        self.highlight_all_lines()
    
    fn highlight_line(inout self, line_idx: Int32):
        """Apply syntax highlighting to a single line."""
        if line_idx < 0 or line_idx >= len(self.lines):
            return
        
        var line = self.lines[line_idx]
        line.tokens.clear()
        
        # Simple tokenization based on language mode
        if self.language_mode == LANG_PLAIN:
            return
        
        # Get keywords for language
        var keywords = self.get_keywords_for_language()
        
        # Simplified tokenization - just highlights keywords, strings, comments, numbers
        let text = line.text
        var i = 0
        
        while i < len(text):
            # Skip whitespace
            if text[i] == ' ' or text[i] == '\t':
                i += 1
                continue
            
            # Comments
            if self.check_comment_start(text, i):
                line.tokens.append(SyntaxToken(i, len(text), TOKEN_COMMENT))
                break
            
            # Strings
            if text[i] == '"' or text[i] == '\'':
                let quote = text[i]
                var end = i + 1
                while end < len(text) and text[end] != quote:
                    if text[end] == '\\' and end + 1 < len(text):
                        end += 2
                    else:
                        end += 1
                if end < len(text):
                    end += 1
                line.tokens.append(SyntaxToken(i, end, TOKEN_STRING))
                i = end
                continue
            
            # Numbers
            if text[i].isdigit():
                var end = i + 1
                while end < len(text) and (text[end].isdigit() or text[end] == '.'):
                    end += 1
                line.tokens.append(SyntaxToken(i, end, TOKEN_NUMBER))
                i = end
                continue
            
            # Identifiers and keywords
            if text[i].isalpha() or text[i] == '_':
                var end = i + 1
                while end < len(text) and (text[end].isalnum() or text[end] == '_'):
                    end += 1
                
                let word = text[i:end]
                var token_type = TOKEN_NORMAL
                
                if word in keywords:
                    token_type = TOKEN_KEYWORD
                elif self.is_type_name(word):
                    token_type = TOKEN_TYPE
                elif end < len(text) and text[end] == '(':
                    token_type = TOKEN_FUNCTION
                
                line.tokens.append(SyntaxToken(i, end, token_type))
                i = end
                continue
            
            # Operators and brackets
            if self.is_operator(text[i]):
                line.tokens.append(SyntaxToken(i, i + 1, TOKEN_OPERATOR))
            elif text[i] in "()[]{}":
                line.tokens.append(SyntaxToken(i, i + 1, TOKEN_BRACKET))
            
            i += 1
        
        self.lines[line_idx] = line
    
    fn highlight_all_lines(inout self):
        """Apply syntax highlighting to all lines."""
        for i in range(len(self.lines)):
            self.highlight_line(i)
    
    fn get_keywords_for_language(self) -> List[String]:
        """Get keywords for current language mode."""
        var keywords = List[String]()
        
        if self.language_mode == LANG_MOJO:
            keywords = ["fn", "struct", "var", "let", "if", "else", "elif", "for", "while",
                       "return", "break", "continue", "import", "from", "alias", "trait",
                       "Self", "self", "inout", "owned", "borrowed", "raises"]
        elif self.language_mode == LANG_PYTHON:
            keywords = ["def", "class", "if", "else", "elif", "for", "while", "return",
                       "break", "continue", "import", "from", "as", "try", "except",
                       "finally", "with", "lambda", "yield", "async", "await"]
        elif self.language_mode == LANG_C or self.language_mode == LANG_CPP:
            keywords = ["if", "else", "for", "while", "do", "switch", "case", "default",
                       "break", "continue", "return", "goto", "sizeof", "typedef",
                       "struct", "union", "enum", "static", "extern", "const", "volatile"]
        
        return keywords
    
    fn is_type_name(self, word: String) -> Bool:
        """Check if word is a type name."""
        let types = ["Int", "Int32", "Int64", "Float", "Float32", "Float64", 
                    "Bool", "String", "void", "int", "float", "double", "char"]
        return word in types
    
    fn is_operator(self, ch: String) -> Bool:
        """Check if character is an operator."""
        return ch in "+-*/%=<>!&|^~"
    
    fn check_comment_start(self, text: String, pos: Int32) -> Bool:
        """Check if position starts a comment."""
        if pos >= len(text):
            return False
        
        if self.language_mode in [LANG_C, LANG_CPP, LANG_MOJO]:
            if pos + 1 < len(text):
                return text[pos:pos+2] == "//" or text[pos:pos+2] == "/*"
        elif self.language_mode == LANG_PYTHON:
            return text[pos] == '#'
        
        return False
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        return True  # Simplified for demo
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
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
        var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")

        # Background
        _ = set_color(self.bg_color.r, self.bg_color.g, self.bg_color.b, self.bg_color.a)
        _ = draw_filled_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)
        
        # Gutter
        _ = set_color(self.gutter_bg_color.r, self.gutter_bg_color.g, self.gutter_bg_color.b, self.gutter_bg_color.a)
        _ = draw_filled_rectangle(self.bounds.x, self.bounds.y, self.gutter_width, self.bounds.height)
        
        # Line numbers and text
        let text_area_x = self.bounds.x + self.gutter_width
        let start_line = self.scroll_y
        let end_line = min(self.scroll_y + self.visible_lines + 1, len(self.lines))
        
        for line_idx in range(start_line, end_line):
            let y = self.bounds.y + (line_idx - self.scroll_y) * self.line_height + 3
            
            # Line number
            _ = set_color(self.line_number_color.r, self.line_number_color.g, self.line_number_color.b, self.line_number_color.a)
            let line_num_str = str(line_idx + 1)
            var line_num_bytes = line_num_str.as_bytes()
            var line_num_ptr = line_num_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(line_num_ptr, self.bounds.x + 10, y, 11)
            
            # Line text with syntax highlighting
            if line_idx < len(self.lines):
                let line = self.lines[line_idx]
                var x = text_area_x + 5
                var last_end = 0
                
                # Render syntax highlighted tokens
                for token in line.tokens:
                    # Render text before token
                    if token.start_col > last_end:
                        let plain_text = line.text[last_end:token.start_col]
                        _ = set_color(self.text_color.r, self.text_color.g, self.text_color.b, self.text_color.a)
                        var plain_bytes = plain_text.as_bytes()
                        var plain_ptr = plain_bytes.unsafe_ptr().bitcast[Int8]()
                        _ = draw_text(plain_ptr, x, y, self.font_size)
                        x += len(plain_text) * self.char_width
                    
                    # Render token with appropriate color
                    let token_text = line.text[token.start_col:token.end_col]
                    let color = self.get_token_color(token.token_type)
                    _ = set_color(color.r, color.g, color.b, color.a)
                    var token_bytes = token_text.as_bytes()
                    var token_ptr = token_bytes.unsafe_ptr().bitcast[Int8]()
                    _ = draw_text(token_ptr, x, y, self.font_size)
                    x += len(token_text) * self.char_width
                    
                    last_end = token.end_col
                
                # Render remaining text
                if last_end < len(line.text):
                    let remaining = line.text[last_end:]
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
    
    fn update(inout self):
        """Update editor state."""
        pass
    
    fn set_focus(inout self, focused: Bool):
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
    return viewer
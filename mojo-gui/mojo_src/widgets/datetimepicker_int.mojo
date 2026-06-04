#!/usr/bin/env mojo
"""
Integer-Only DateTime Picker Widget Implementation
Professional date and time selection widget with calendar view.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .button_int import ButtonInt
from .textedit_int import TextEditInt

# Date picker modes
comptime PICKER_DATE = 0
comptime PICKER_TIME = 1
comptime PICKER_DATETIME = 2

# Calendar view modes
comptime VIEW_DAYS = 0
comptime VIEW_MONTHS = 1
comptime VIEW_YEARS = 2

fn _zfill(value: Int32, width: Int) -> String:
    """Left-pad the string form of an integer with zeros to the given width."""
    var s = String(value)
    while len(s) < width:
        s = "0" + s
    return s

struct DateTime(Copyable, Movable):
    """Date and time representation."""
    var year: Int32
    var month: Int32
    var day: Int32
    var hour: Int32
    var minute: Int32
    var second: Int32

    fn __init__(out self, year: Int32 = 2024, month: Int32 = 1, day: Int32 = 1,
                hour: Int32 = 0, minute: Int32 = 0, second: Int32 = 0):
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second

    fn is_valid(self) -> Bool:
        """Check if date/time is valid."""
        if self.month < 1 or self.month > 12:
            return False
        if self.day < 1 or self.day > self.days_in_month():
            return False
        if self.hour < 0 or self.hour > 23:
            return False
        if self.minute < 0 or self.minute > 59:
            return False
        if self.second < 0 or self.second > 59:
            return False
        return True

    fn days_in_month(self) -> Int32:
        """Get number of days in current month."""
        var days_per_month = List[Int32]()
        days_per_month.append(31)
        days_per_month.append(28)
        days_per_month.append(31)
        days_per_month.append(30)
        days_per_month.append(31)
        days_per_month.append(30)
        days_per_month.append(31)
        days_per_month.append(31)
        days_per_month.append(30)
        days_per_month.append(31)
        days_per_month.append(30)
        days_per_month.append(31)
        if self.month < 1 or self.month > 12:
            return 30

        var days = days_per_month[Int(self.month) - 1]

        # Check for leap year (February)
        if self.month == 2 and self.is_leap_year():
            days = 29

        return days

    fn is_leap_year(self) -> Bool:
        """Check if current year is a leap year."""
        return (self.year % 4 == 0 and self.year % 100 != 0) or (self.year % 400 == 0)

    fn day_of_week(self) -> Int32:
        """Get day of week (0=Sunday, 6=Saturday) using Zeller's congruence."""
        var year = self.year
        var month = self.month

        # Adjust for Zeller's algorithm
        if month < 3:
            month += 12
            year -= 1

        var century = year // 100
        var year_of_century = year % 100

        var h = (self.day + (13 * (month + 1)) // 5 + year_of_century +
                year_of_century // 4 + century // 4 - 2 * century) % 7

        # Convert to 0=Sunday format
        return (h + 6) % 7

    fn to_string(self, include_time: Bool = True) -> String:
        """Convert to string representation."""
        var date_str = String(self.year) + "-" + _zfill(self.month, 2) + "-" + _zfill(self.day, 2)

        if include_time:
            date_str += " " + _zfill(self.hour, 2) + ":" + _zfill(self.minute, 2) + ":" + _zfill(self.second, 2)

        return date_str

struct DateTimePickerInt(WidgetInt, Copyable, Movable):
    """Date and time picker widget with calendar view."""

    # Inlined BaseWidgetInt fields (struct inheritance is not supported).
    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    var background_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32

    var selected_date: DateTime
    var current_view_date: DateTime
    var picker_mode: Int32
    var view_mode: Int32
    var is_expanded: Bool
    var show_week_numbers: Bool
    var first_day_of_week: Int32  # 0=Sunday, 1=Monday
    var date_format: String
    var time_format_24h: Bool

    # Layout
    var header_height: Int32
    var day_cell_size: Int32
    var time_field_width: Int32
    var dropdown_width: Int32
    var dropdown_height: Int32

    # Colors
    var text_color: ColorInt
    var header_color: ColorInt
    var weekday_color: ColorInt
    var day_color: ColorInt
    var day_hover_color: ColorInt
    var day_selected_color: ColorInt
    var day_today_color: ColorInt
    var day_other_month_color: ColorInt
    var weekend_color: ColorInt
    var week_number_color: ColorInt

    # Interaction
    var hover_day: Int32
    var hover_month: Int32
    var hover_year: Int32
    var dragging_time: Int32  # 0=none, 1=hour, 2=minute, 3=second
    var dropdown_rect: RectInt

    # Animation
    var animation_progress: Float32
    var animation_direction: Int32

    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32,
                mode: Int32 = PICKER_DATE):
        # Inlined BaseWidgetInt.__init__
        self.bounds = RectInt(x, y, width, height)
        self.visible = True
        self.enabled = True
        self.background_color = ColorInt(230, 230, 230, 255)
        self.border_color = ColorInt(128, 128, 128, 255)
        self.border_width = 1

        # Initialize dates
        self.selected_date = DateTime(2024, 1, 1, 12, 0, 0)
        self.current_view_date = DateTime(2024, 1, 1, 12, 0, 0)

        self.picker_mode = mode
        self.view_mode = VIEW_DAYS
        self.is_expanded = False
        self.show_week_numbers = True
        self.first_day_of_week = 0
        self.date_format = "YYYY-MM-DD"
        self.time_format_24h = True

        # Layout
        self.header_height = 35
        self.day_cell_size = 32
        self.time_field_width = 60
        self.dropdown_width = 300
        self.dropdown_height = 320

        # Colors
        self.text_color = ColorInt(0, 0, 0, 255)
        self.header_color = ColorInt(70, 130, 180, 255)  # Steel blue
        self.weekday_color = ColorInt(100, 100, 100, 255)
        self.day_color = ColorInt(0, 0, 0, 255)
        self.day_hover_color = ColorInt(220, 230, 240, 255)
        self.day_selected_color = ColorInt(70, 130, 180, 255)
        self.day_today_color = ColorInt(255, 200, 200, 255)
        self.day_other_month_color = ColorInt(180, 180, 180, 255)
        self.weekend_color = ColorInt(200, 0, 0, 255)
        self.week_number_color = ColorInt(150, 150, 150, 255)

        # Interaction
        self.hover_day = -1
        self.hover_month = -1
        self.hover_year = -1
        self.dragging_time = 0
        self.dropdown_rect = RectInt(x, y + height, self.dropdown_width, self.dropdown_height)

        # Animation
        self.animation_progress = 0.0
        self.animation_direction = 0

        # Appearance
        self.background_color = ColorInt(255, 255, 255, 255)
        self.border_color = ColorInt(180, 180, 180, 255)
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

    fn set_date(mut self, date: DateTime):
        """Set the selected date."""
        if date.is_valid():
            self.selected_date = date
            self.current_view_date = date

    fn get_date(self) -> DateTime:
        """Get the selected date."""
        return self.selected_date

    fn set_time_format_24h(mut self, use_24h: Bool):
        """Set whether to use 24-hour time format."""
        self.time_format_24h = use_24h

    fn format_date(self, date: DateTime) -> String:
        """Format date according to format string."""
        # Simple implementation - could be expanded
        return date.to_string(False)

    fn format_time(self, date: DateTime) -> String:
        """Format time according to settings."""
        if self.time_format_24h:
            return _zfill(date.hour, 2) + ":" + _zfill(date.minute, 2)
        else:
            var hour = date.hour % 12
            if hour == 0:
                hour = 12
            var am_pm = String("AM") if date.hour < 12 else String("PM")
            return String(hour) + ":" + _zfill(date.minute, 2) + " " + am_pm

    fn get_calendar_days(self) -> List[List[Int32]]:
        """Get calendar days for current view month."""
        var calendar = List[List[Int32]]()

        # Get first day of month
        var first_day = DateTime(self.current_view_date.year,
                                self.current_view_date.month, 1)
        var first_weekday = first_day.day_of_week()

        # Calculate starting date (may be in previous month)
        var start_offset = (first_weekday - self.first_day_of_week + 7) % 7

        # Fill calendar weeks
        var current_day = 1 - start_offset

        for week in range(6):  # Max 6 weeks in view
            var week_days = List[Int32]()

            for day in range(7):
                week_days.append(current_day)
                current_day += 1

            calendar.append(week_days^)

            # Stop if we've gone well past the end of the month
            if current_day > first_day.days_in_month() + 7:
                break

        return calendar^

    fn handle_mouse_event(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False

        var point = PointInt(event.x, event.y)

        # Check main field click to toggle dropdown
        if self.contains_point(point) and event.pressed:
            self.is_expanded = not self.is_expanded
            return True

        # Handle dropdown interactions if expanded
        if self.is_expanded:
            self.update_dropdown_rect()

            if self.dropdown_rect.contains(point):
                if self.view_mode == VIEW_DAYS:
                    return self.handle_calendar_mouse(event)
                elif self.view_mode == VIEW_MONTHS:
                    return self.handle_month_grid_mouse(event)
                elif self.view_mode == VIEW_YEARS:
                    return self.handle_year_grid_mouse(event)
            elif event.pressed:
                # Click outside closes dropdown
                self.is_expanded = False
                return False

        return False

    fn handle_calendar_mouse(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse in calendar view."""
        var point = PointInt(event.x, event.y)

        # Check header buttons
        var header_y = self.dropdown_rect.y

        # Previous month button
        var prev_rect = RectInt(self.dropdown_rect.x + 5, header_y + 5, 25, 25)
        if prev_rect.contains(point) and event.pressed:
            self.navigate_month(-1)
            return True

        # Next month button
        var next_rect = RectInt(self.dropdown_rect.x + self.dropdown_width - 30,
                               header_y + 5, 25, 25)
        if next_rect.contains(point) and event.pressed:
            self.navigate_month(1)
            return True

        # Month/year label (switch to month/year view)
        var label_rect = RectInt(self.dropdown_rect.x + 35, header_y + 5,
                                self.dropdown_width - 70, 25)
        if label_rect.contains(point) and event.pressed:
            self.view_mode = VIEW_MONTHS
            return True

        # Check day cells
        var calendar_start_y = header_y + self.header_height + 25  # Space for weekday headers
        var cell_start_x = self.dropdown_rect.x + (30 if self.show_week_numbers else 5)

        var calendar = self.get_calendar_days()

        for week in range(len(calendar)):
            for day in range(7):
                var cell_x = cell_start_x + day * self.day_cell_size
                var cell_y = calendar_start_y + week * self.day_cell_size
                var cell_rect = RectInt(cell_x, cell_y, self.day_cell_size, self.day_cell_size)

                if cell_rect.contains(point):
                    var day_value = calendar[week][day]

                    if event.pressed:
                        # Update selected date
                        var new_month = self.current_view_date.month
                        var new_year = self.current_view_date.year

                        if day_value < 1:
                            # Previous month
                            new_month -= 1
                            if new_month < 1:
                                new_month = 12
                                new_year -= 1
                            day_value = DateTime(new_year, new_month, 1).days_in_month() + day_value
                        elif day_value > self.current_view_date.days_in_month():
                            # Next month
                            day_value -= self.current_view_date.days_in_month()
                            new_month += 1
                            if new_month > 12:
                                new_month = 1
                                new_year += 1

                        self.selected_date.year = new_year
                        self.selected_date.month = new_month
                        self.selected_date.day = day_value

                        if self.picker_mode == PICKER_DATE:
                            self.is_expanded = False

                        return True
                    else:
                        self.hover_day = week * 7 + day
                        return True

        return True

    fn handle_month_grid_mouse(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse in month selection view."""
        # Simplified - would implement month grid selection
        if event.pressed:
            self.view_mode = VIEW_DAYS
        return True

    fn handle_year_grid_mouse(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse in year selection view."""
        # Simplified - would implement year grid selection
        if event.pressed:
            self.view_mode = VIEW_MONTHS
        return True

    fn navigate_month(mut self, delta: Int32):
        """Navigate to previous/next month."""
        self.current_view_date.month += delta

        if self.current_view_date.month < 1:
            self.current_view_date.month = 12
            self.current_view_date.year -= 1
        elif self.current_view_date.month > 12:
            self.current_view_date.month = 1
            self.current_view_date.year += 1

        self.animation_direction = delta
        self.animation_progress = 0.0

    fn update_dropdown_rect(mut self):
        """Update dropdown rectangle position."""
        # Position below or above the main field depending on space
        self.dropdown_rect.x = self.bounds.x
        self.dropdown_rect.y = self.bounds.y + self.bounds.height + 2
        self.dropdown_rect.width = self.dropdown_width
        self.dropdown_rect.height = self.dropdown_height

    fn handle_key_event(mut self, event: KeyEventInt) -> Bool:
        """Handle key events (not typically used)."""
        return False

    fn render(self, ctx: RenderingContextInt):
        """Render the date/time picker."""
        if not self.visible:
            return

        # Render main field
        self.render_field(ctx)

        # Render dropdown if expanded
        if self.is_expanded:
            self.render_dropdown(ctx)

    fn render_field(self, ctx: RenderingContextInt):
        """Render the main date/time field."""
        # Background
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y,
                                     self.bounds.width, self.bounds.height)

        # Display text
        var display_text = String("")
        if self.picker_mode == PICKER_DATE:
            display_text = self.format_date(self.selected_date)
        elif self.picker_mode == PICKER_TIME:
            display_text = self.format_time(self.selected_date)
        else:
            display_text = self.format_date(self.selected_date) + " " +
                          self.format_time(self.selected_date)

        _ = ctx.set_color(self.text_color.r, self.text_color.g,
                         self.text_color.b, self.text_color.a)
        _ = ctx.draw_text(display_text, self.bounds.x + 8, self.bounds.y + 8, 12)

        # Calendar icon
        var icon_x = self.bounds.x + self.bounds.width - 25
        var icon_y = self.bounds.y + 8
        _ = ctx.draw_rectangle(icon_x, icon_y, 16, 14)
        _ = ctx.draw_line(icon_x, icon_y + 4, icon_x + 16, icon_y + 4, 1)

        # Border
        var border_color = self.header_color if self.is_expanded else self.border_color
        _ = ctx.set_color(border_color.r, border_color.g,
                         border_color.b, border_color.a)
        _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y,
                              self.bounds.width, self.bounds.height)

    fn render_dropdown(self, ctx: RenderingContextInt):
        """Render the dropdown calendar/time selector."""
        # Shadow
        _ = ctx.set_color(0, 0, 0, 30)
        _ = ctx.draw_filled_rectangle(self.dropdown_rect.x + 2, self.dropdown_rect.y + 2,
                                     self.dropdown_rect.width, self.dropdown_rect.height)

        # Background
        _ = ctx.set_color(255, 255, 255, 255)
        _ = ctx.draw_filled_rectangle(self.dropdown_rect.x, self.dropdown_rect.y,
                                     self.dropdown_rect.width, self.dropdown_rect.height)

        # Render based on view mode
        if self.view_mode == VIEW_DAYS:
            self.render_calendar_view(ctx)
        elif self.view_mode == VIEW_MONTHS:
            self.render_month_grid(ctx)
        elif self.view_mode == VIEW_YEARS:
            self.render_year_grid(ctx)

        # Time controls if needed
        if self.picker_mode == PICKER_TIME or self.picker_mode == PICKER_DATETIME:
            self.render_time_controls(ctx)

        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(self.dropdown_rect.x, self.dropdown_rect.y,
                              self.dropdown_rect.width, self.dropdown_rect.height)

    fn render_calendar_view(self, ctx: RenderingContextInt):
        """Render calendar days view."""
        var start_x = self.dropdown_rect.x
        var start_y = self.dropdown_rect.y

        # Header
        _ = ctx.set_color(self.header_color.r, self.header_color.g,
                         self.header_color.b, self.header_color.a)
        _ = ctx.draw_filled_rectangle(start_x, start_y,
                                     self.dropdown_rect.width, self.header_height)

        # Navigation buttons
        _ = ctx.set_color(255, 255, 255, 255)

        # Previous month
        _ = ctx.draw_text("<", start_x + 10, start_y + 10, 16)

        # Next month
        _ = ctx.draw_text(">", start_x + self.dropdown_rect.width - 20, start_y + 10, 16)

        # Month/Year label
        var month_names = List[String]()
        month_names.append("January")
        month_names.append("February")
        month_names.append("March")
        month_names.append("April")
        month_names.append("May")
        month_names.append("June")
        month_names.append("July")
        month_names.append("August")
        month_names.append("September")
        month_names.append("October")
        month_names.append("November")
        month_names.append("December")
        var month_text = month_names[Int(self.current_view_date.month) - 1] + " " +
                        String(self.current_view_date.year)
        var text_width = len(month_text) * 8
        _ = ctx.draw_text(month_text, start_x + (self.dropdown_rect.width - text_width) // 2,
                         start_y + 10, 14)

        # Weekday headers
        var weekdays = List[String]()
        weekdays.append("Su")
        weekdays.append("Mo")
        weekdays.append("Tu")
        weekdays.append("We")
        weekdays.append("Th")
        weekdays.append("Fr")
        weekdays.append("Sa")
        var calendar_start_x = start_x + (30 if self.show_week_numbers else 5)
        var header_y = start_y + self.header_height + 5

        _ = ctx.set_color(self.weekday_color.r, self.weekday_color.g,
                         self.weekday_color.b, self.weekday_color.a)

        for i in range(7):
            var day_idx = (i + Int(self.first_day_of_week)) % 7
            var x = calendar_start_x + i * self.day_cell_size + 8
            _ = ctx.draw_text(weekdays[day_idx], x, header_y, 11)

        # Calendar days
        var calendar = self.get_calendar_days()
        var calendar_start_y = header_y + 20

        # Get today's date for highlighting
        # In real implementation, would get actual current date
        var today = DateTime(2024, 1, 15)

        for week in range(len(calendar)):
            # Week number
            if self.show_week_numbers:
                _ = ctx.set_color(self.week_number_color.r, self.week_number_color.g,
                                 self.week_number_color.b, self.week_number_color.a)
                _ = ctx.draw_text("W" + String(week + 1), start_x + 5,
                                 calendar_start_y + week * self.day_cell_size + 8, 10)

            for day in range(7):
                var day_value = calendar[week][day]
                var cell_x = calendar_start_x + day * self.day_cell_size
                var cell_y = calendar_start_y + week * self.day_cell_size
                var cell_idx = week * 7 + day

                # Determine if this is current month
                var is_current_month = (day_value >= 1 and
                                       day_value <= self.current_view_date.days_in_month())

                # Background for hover/selected
                if Int32(cell_idx) == self.hover_day:
                    _ = ctx.set_color(self.day_hover_color.r, self.day_hover_color.g,
                                     self.day_hover_color.b, self.day_hover_color.a)
                    _ = ctx.draw_filled_rectangle(cell_x, cell_y,
                                                 self.day_cell_size, self.day_cell_size)

                # Check if selected
                var actual_day = day_value
                if is_current_month and
                   actual_day == self.selected_date.day and
                   self.current_view_date.month == self.selected_date.month and
                   self.current_view_date.year == self.selected_date.year:
                    _ = ctx.set_color(self.day_selected_color.r, self.day_selected_color.g,
                                     self.day_selected_color.b, self.day_selected_color.a)
                    _ = ctx.draw_filled_rectangle(cell_x + 2, cell_y + 2,
                                                 self.day_cell_size - 4, self.day_cell_size - 4)

                # Day number
                var text_color = self.day_color
                if not is_current_month:
                    text_color = self.day_other_month_color
                elif day % 7 == 0 or day % 7 == 6:  # Weekend
                    text_color = self.weekend_color

                _ = ctx.set_color(text_color.r, text_color.g, text_color.b, text_color.a)

                var display_day = actual_day if actual_day > 0 else
                                 (self.current_view_date.days_in_month() + actual_day)
                _ = ctx.draw_text(String(display_day), cell_x + 10, cell_y + 8, 12)

    fn render_month_grid(self, ctx: RenderingContextInt):
        """Render month selection grid."""
        # Header
        _ = ctx.set_color(self.header_color.r, self.header_color.g,
                         self.header_color.b, self.header_color.a)
        _ = ctx.draw_filled_rectangle(self.dropdown_rect.x, self.dropdown_rect.y,
                                     self.dropdown_rect.width, self.header_height)

        _ = ctx.set_color(255, 255, 255, 255)
        _ = ctx.draw_text(String(self.current_view_date.year),
                         self.dropdown_rect.x + self.dropdown_rect.width // 2 - 20,
                         self.dropdown_rect.y + 10, 14)

        # Month grid (4x3)
        var month_names = List[String]()
        month_names.append("Jan")
        month_names.append("Feb")
        month_names.append("Mar")
        month_names.append("Apr")
        month_names.append("May")
        month_names.append("Jun")
        month_names.append("Jul")
        month_names.append("Aug")
        month_names.append("Sep")
        month_names.append("Oct")
        month_names.append("Nov")
        month_names.append("Dec")

        var grid_start_x = self.dropdown_rect.x + 20
        var grid_start_y = self.dropdown_rect.y + self.header_height + 20
        var cell_width = (self.dropdown_rect.width - 40) // 4
        var cell_height = 40

        for month in range(12):
            var row = month // 4
            var col = month % 4
            var x = grid_start_x + col * cell_width
            var y = grid_start_y + row * cell_height

            # Highlight current month
            if Int32(month + 1) == self.selected_date.month:
                _ = ctx.set_color(self.day_selected_color.r, self.day_selected_color.g,
                                 self.day_selected_color.b, self.day_selected_color.a)
                _ = ctx.draw_filled_rectangle(x, y, cell_width - 5, cell_height - 5)

            _ = ctx.set_color(self.day_color.r, self.day_color.g,
                             self.day_color.b, self.day_color.a)
            _ = ctx.draw_text(month_names[month], x + 15, y + 12, 12)

    fn render_year_grid(self, ctx: RenderingContextInt):
        """Render year selection grid."""
        # Simplified - would show decade view
        _ = ctx.set_color(self.header_color.r, self.header_color.g,
                         self.header_color.b, self.header_color.a)
        _ = ctx.draw_filled_rectangle(self.dropdown_rect.x, self.dropdown_rect.y,
                                     self.dropdown_rect.width, self.header_height)

    fn render_time_controls(self, ctx: RenderingContextInt):
        """Render time selection controls."""
        var time_y = self.dropdown_rect.y + self.dropdown_rect.height - 50
        var time_x = self.dropdown_rect.x + 20

        # Separator
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_line(self.dropdown_rect.x + 10, time_y - 10,
                         self.dropdown_rect.x + self.dropdown_rect.width - 10, time_y - 10, 1)

        # Time fields
        _ = ctx.set_color(self.day_color.r, self.day_color.g,
                         self.day_color.b, self.day_color.a)
        _ = ctx.draw_text("Time:", time_x, time_y + 5, 12)

        # Hour field
        var hour_x = time_x + 40
        _ = ctx.draw_rectangle(hour_x, time_y, 30, 25)
        _ = ctx.draw_text(_zfill(self.selected_date.hour, 2), hour_x + 8, time_y + 5, 12)

        _ = ctx.draw_text(":", hour_x + 35, time_y + 5, 12)

        # Minute field
        var minute_x = hour_x + 45
        _ = ctx.draw_rectangle(minute_x, time_y, 30, 25)
        _ = ctx.draw_text(_zfill(self.selected_date.minute, 2), minute_x + 8, time_y + 5, 12)

        if not self.time_format_24h:
            # AM/PM selector
            var ampm_x = minute_x + 40
            var is_pm = self.selected_date.hour >= 12
            _ = ctx.draw_rectangle(ampm_x, time_y, 35, 25)
            _ = ctx.draw_text(String("PM") if is_pm else String("AM"), ampm_x + 8, time_y + 5, 12)

    fn update(mut self):
        """Update animations."""
        if self.animation_progress < 1.0:
            self.animation_progress += 0.1
            if self.animation_progress > 1.0:
                self.animation_progress = 1.0


# Convenience functions
fn create_date_picker_int(x: Int32, y: Int32, width: Int32 = 200, height: Int32 = 30) -> DateTimePickerInt:
    """Create a date picker."""
    return DateTimePickerInt(x, y, width, height, PICKER_DATE)

fn create_time_picker_int(x: Int32, y: Int32, width: Int32 = 120, height: Int32 = 30) -> DateTimePickerInt:
    """Create a time picker."""
    return DateTimePickerInt(x, y, width, height, PICKER_TIME)

fn create_datetime_picker_int(x: Int32, y: Int32, width: Int32 = 250, height: Int32 = 30) -> DateTimePickerInt:
    """Create a date and time picker."""
    return DateTimePickerInt(x, y, width, height, PICKER_DATETIME)

# Helper to get current date/time (placeholder - would use system time)
fn get_current_datetime() -> DateTime:
    """Get current date and time."""
    # In real implementation, would get system time
    return DateTime(2024, 1, 15, 14, 30, 0)

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */

public class SearchButton : Gtk.Box {

    Gtk.Entry entry_search;
    Gtk.ToggleButton toggle_search;
    Gtk.ToggleButton toggle_match;
    Gtk.Button previous;
    Gtk.Button next;
    public Gtk.TextBuffer buffer {get; construct;}

    public bool active {
        get {return toggle_search.active;}
        set {toggle_search.active = value;}
    }

    Gtk.TextSearchFlags flags {
        get {
            if (toggle_match.active) {
                return Gtk.TextSearchFlags.TEXT_ONLY;
            }
            return Gtk.TextSearchFlags.CASE_INSENSITIVE;
        }
        set {
            toggle_match.active = (value == Gtk.TextSearchFlags.TEXT_ONLY);
        }
    }

    public SearchButton (Gtk.TextBuffer buffer) {
        Object (buffer: buffer);
    }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 3;

        toggle_search = new Gtk.ToggleButton () {
            icon_name = "system-search",
            tooltip_markup = Granite.markup_accel_tooltip (
                    {"<Control>f"},
                    _("Search")
            )
        };

        var search_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        search_box.add_css_class (Granite.STYLE_CLASS_LINKED);

        entry_search = new Gtk.Entry () {
            placeholder_text = _("Enter search term"),
            secondary_icon_tooltip_text = _("Clear text"),
        };

        previous = new Gtk.Button.from_icon_name ("go-down-symbolic");
        next = new Gtk.Button.from_icon_name ("go-up-symbolic");
        toggle_match = new Gtk.ToggleButton () {
            icon_name = "font-select-symbolic",
            tooltip_text = _("Match case")
        };

        search_box.append (entry_search);
        search_box.append (previous);
        search_box.append (next);
        search_box.append (toggle_match);

        var revealer_search = new Gtk.Revealer () {
            child = search_box,
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };

        append (revealer_search);
        append (toggle_search);


        /* ---------------- CONNECTS AND BINDS ---------------- */
        toggle_search.bind_property ("active",
            revealer_search, "reveal-child",
            GLib.BindingFlags.SYNC_CREATE);

        entry_search.changed.connect (on_entry_changed);
        entry_search.changed.connect (() => {search_text ();});
        entry_search.icon_release.connect (on_clear_clicked);

        previous.clicked.connect (() => {search_text (false);});
        next.clicked.connect (() => {search_text (true);});

        revealer_search.notify["reveal-child"].connect (() => {entry_search.grab_focus ();});
    }

    private void on_entry_changed () {
        if (entry_search.text_length > 0) {
            entry_search.secondary_icon_name = "edit-clear-symbolic";

        } else {
            entry_search.secondary_icon_name = "";
        }
    }

    private void on_clear_clicked () {
        entry_search.text = "";
    }

    private void search_text (bool? forward = true) {
        Gtk.TextIter start_selection, end_selection;
        buffer.get_selection_bounds (out start_selection, out end_selection);

        Gtk.TextIter start_buffer, end_buffer;
        buffer.get_bounds (out start_buffer, out end_buffer);

        Gtk.TextIter match_start, match_end;
        bool found_match;

        if (forward) {
            found_match = end_selection.forward_search (entry_search.text, flags,
                out match_start, out match_end, start_buffer);
        } else {
            found_match = start_selection.backward_search (entry_search.text, flags,
                out match_start, out match_end, end_buffer);
        }

        buffer.select_range (match_start, match_end);
    }
}

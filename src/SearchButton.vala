/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */

public class SearchButton : Gtk.Box {

    public Gtk.MenuButton search_menu;
    Gtk.Entry entry_search;
    Gtk.ToggleButton toggle_match;
    Gtk.Button previous;
    Gtk.Button next;
    public Gtk.TextView textview {get; construct;}
    public Gtk.TextBuffer buffer {get; construct;}

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

    public SearchButton (Gtk.TextView textview) {
        Object (
            textview: textview,
            buffer: textview.buffer
        );
    }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 0;

        search_menu = new Gtk.MenuButton () {
            icon_name = "system-search",
            tooltip_markup = Granite.markup_accel_tooltip (
                    {"<Control>f"},
                    _("Search")
            )
        };

        var search_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 10,
            margin_end = 10,
            margin_top = 10,
            margin_bottom = 10
        };
        search_box.add_css_class (Granite.STYLE_CLASS_LINKED);

        entry_search = new Gtk.Entry () {
            placeholder_text = _("Enter search term"),
            secondary_icon_tooltip_text = _("Clear text"),
        };

        previous = new Gtk.Button.from_icon_name ("go-up-symbolic");
        next = new Gtk.Button.from_icon_name ("go-down-symbolic");
        toggle_match = new Gtk.ToggleButton () {
            icon_name = "font-select-symbolic",
            tooltip_text = _("Match case")
        };

        search_box.append (entry_search);
        search_box.append (previous);
        search_box.append (next);
        search_box.append (toggle_match);


        var popover = new Gtk.Popover () {
            child = search_box
        };

        search_menu.popover = popover;
        append (search_menu);


        /* ---------------- CONNECTS AND BINDS ---------------- */


        entry_search.changed.connect (on_entry_changed);
        entry_search.icon_release.connect (on_clear_clicked);

        previous.clicked.connect (() => {search_text (false);});
        next.clicked.connect (() => {search_text (true);});
        entry_search.activate.connect (() => {search_text (true);});

        popover.show.connect (() => {entry_search.grab_focus ();});

        var settings = new GLib.Settings ("io.github.wpkelso.slate");
        settings.bind ("match-case",
            toggle_match, "active",
            GLib.SettingsBindFlags.DEFAULT);
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
        print ("\nSearch start");

        Gtk.TextIter start_selection, end_selection;
        buffer.get_selection_bounds (out start_selection, out end_selection);

        print ("\nbounds start");

        Gtk.TextIter start_buffer, end_buffer;
        buffer.get_bounds (out start_buffer, out end_buffer);

        Gtk.TextIter match_start, match_end;
        bool found_match;
        var text = entry_search.text;

        if (forward) {
            print ("\nfw");
                found_match = end_selection.forward_search (text, flags,
                out match_start, out match_end, null);

        } else {

            print ("\nbackward");
               found_match = start_selection.backward_search (text, flags,
                    out match_start, out match_end, null);

        }
            print ("\nFound: " + found_match.to_string () + " at? " + match_start.get_offset ().to_string ());

        if (found_match) {
            buffer.select_range (match_start, match_end);
            textview.scroll_to_iter (match_start, 0, false, 0.5f, 0.5f);
        }

    }
}

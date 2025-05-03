/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */

public class Application : Gtk.Application {
    public Application () {
        Object (
            application_id: "io.elementary.text",
            flags: ApplicationFlags.DEFAULT_FLAGS
        );
    }


    public override void startup () {
        Granite.init ();
        base.startup ();
    }


    protected override void activate () {

        var header = new Gtk.HeaderBar () {
            show_title_buttons = false
        };
        header.add_css_class (Granite.STYLE_CLASS_FLAT);
        header.pack_start (new Gtk.WindowControls (Gtk.PackType.START));
        header.pack_end (new Gtk.WindowControls (Gtk.PackType.END));

        var view = new Gtk.TextView () {
            cursor_visible = true,
            editable = true,
            monospace = true,
            left_margin = 12,
            right_margin = 12,
            top_margin = 6,
            bottom_margin = 6,
            wrap_mode = WORD_CHAR,
        };
        
        var app_box = new Granite.Box (VERTICAL);
        app_box.append (header);
        app_box.append (view);
            

        var window = new Gtk.Window () {
            child = app_box,
            default_height = 650,
            default_width = 600,
            titlebar = new Gtk.Grid () { visible = false },
            title = "Text"
        };
        add_window (window);
        window.show ();
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}

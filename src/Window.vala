/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */

public class AppWindow : Gtk.Window {
    public File file { get; set; }
    private Gtk.TextBuffer buf;
    public string file_name { get; set; default = "unknown"; }
    public bool is_new { get; set; default = false; }

    public AppWindow () {
        debug ("Constructing GUI");

        Intl.setlocale ();

        var new_button = new Gtk.Button.from_icon_name ("document-new") {
            action_name = "app.new-document",
            tooltip_markup = Granite.markup_accel_tooltip (
                    {""},
                    _("New Document")
            )
        };
        var open_button = new Gtk.Button.from_icon_name ("document-open") {
            action_name = "app.open-document",
            tooltip_markup = Granite.markup_accel_tooltip (
                    {""},
                    _("Open file")
            )
        };
        var save_as_button = new Gtk.Button.from_icon_name ("document-save-as") {
            tooltip_markup = Granite.markup_accel_tooltip (
                    {""},
                    _("Save as")
            )
        };

        // TODO: use Granite.Box (HORIZONTAL, HALF) when granite-7.7.0 is released
        var actions_box = new Gtk.Box (HORIZONTAL, 8);
        actions_box.append (new_button);
        actions_box.append (open_button);
        actions_box.append (save_as_button);


        var header = new Gtk.HeaderBar () {
            show_title_buttons = true
        };
        header.add_css_class (Granite.STYLE_CLASS_FLAT);
        header.pack_start (actions_box);

        var text_view = new Gtk.TextView () {
            cursor_visible = true,
            editable = true,
            monospace = true,
            left_margin = 12,
            right_margin = 12,
            top_margin = 6,
            bottom_margin = 6,
            wrap_mode = WORD_CHAR,
        };
        buf = text_view.buffer;


        var scrolled_view = new Gtk.ScrolledWindow () {
            child = text_view,
            hexpand = true,
            vexpand = true,
        };

        child = scrolled_view;
        default_height = 400;
        default_width = 300;
        titlebar = header;

        debug ("Connecting signals");

        // Signal callbacks are heavily derived from similar operations in
        // elementary/code
        save_as_button.clicked.connect (() => {
            var save_dialog = new Gtk.FileDialog () { initial_name = file_name };

            save_dialog.save.begin (this, null, (obj, res) => {
                try {
                    file = save_dialog.save.end (res);
                    file_name = file.get_basename ();
                    if (is_new) { is_new = false; }
                    save_file (file);
                } catch (Error err) {
                    warning ("Failed to save file: %s", err.message);
                }
            });
        });

        this.close_request.connect (() => {
            save_file ();

            if (is_new) {
                try {
                    this.file.delete ();
                } catch (Error err) {
                    warning (
                             "The persistent file couldn't be deleted: %s",
                             err.message
                    );
                }
            }

            return false;
        });

        // Add a debounce so we aren't writing the entire buffer every character input
        var interval = 500; // ms
        uint debounce_timer_id = 0;

        buf.changed.connect (() => {
            debug ("The buffer has been modified, starting the debounce timer");

            if (debounce_timer_id != 0) {
                GLib.Source.remove (debounce_timer_id);
            }

            debounce_timer_id = Timeout.add (interval, () => {
                debounce_timer_id = 0;
                if (file.query_exists ()) {
                    save_file ();
                }
                return GLib.Source.REMOVE;
            });
        });

        debug ("Binding window title to file_name");

        bind_property ("file_name", this, "title");

        debug ("Success!");
    }

    public void open_file (File file = this.file) {
        this.file = file;

        if (this.is_new) {
            try {
                file.create (GLib.FileCreateFlags.REPLACE_DESTINATION);
                this.file_name = file.get_basename ();
            } catch (Error err) {
                warning ("Couldn't create file: %s", err.message);
            }
        } else {
            debug ("Attempting to open file %s", file.get_basename ());
            try {
                this.file_name = file.get_basename ();
                var distream = new DataInputStream (file.read (null));
                var contents = distream.read_upto ("", -1, null);
                buf.set_text (contents);
            } catch (Error err) {
                warning ("Couldn't open file: %s", err.message);
            }
        }
    }

    public void save_file (File file = this.file) {
        try {
            debug ("Attempting to save the buffer to disk..");
            DataOutputStream dostream;
            dostream = new DataOutputStream (
                                             file.replace (
                                                           null,
                                                           false,
                                                           GLib.FileCreateFlags.REPLACE_DESTINATION
                                             )
            );

            var contents = buf.text;
            dostream.put_string (contents);
        } catch (Error err) {
            warning ("Couldn't save file: %s", err.message);
        }
    }
}

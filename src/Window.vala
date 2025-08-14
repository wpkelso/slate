/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */

public class AppWindow : Gtk.Window {
    public File file { get; set; }
    private Gtk.TextBuffer buf;
    private Gtk.HeaderBar header;
    public string file_name { get; set; }

    // Add a debounce so we aren't writing the entire buffer every character input
    public int interval = 500; // ms
    public uint debounce_timer_id = 0;

    public AppWindow (File file) {
        debug ("Constructing GUI");

        Intl.setlocale ();

        var new_button = new Gtk.Button.from_icon_name ("document-new") {
            action_name = "app.new-document",
            tooltip_markup = Granite.markup_accel_tooltip (
                    {"<Control>n"},
                    _("New Document")
            )
        };
        var open_button = new Gtk.Button.from_icon_name ("document-open") {
            action_name = "app.open-document",
            tooltip_markup = Granite.markup_accel_tooltip (
                    {"<Control>o"},
                    _("Open file")
            )
        };
        var save_as_button = new Gtk.Button.from_icon_name ("document-save-as") {
            tooltip_markup = Granite.markup_accel_tooltip (
                    {"<Control><Shift>s"},
                    _("Save as")
            )
        };

        // TODO: use Granite.Box (HORIZONTAL, HALF) when granite-7.7.0 is released
        var actions_box = new Gtk.Box (HORIZONTAL, 8);
        actions_box.append (new_button);
        actions_box.append (open_button);
        actions_box.append (save_as_button);

        header = new Gtk.HeaderBar () {
            show_title_buttons = true,
            tooltip_text = ""
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
        buf.text = "";


        var scrolled_view = new Gtk.ScrolledWindow () {
            child = text_view,
            hexpand = true,
            vexpand = true,
        };

        child = scrolled_view;
        default_height = 400;
        default_width = 300;
        titlebar = header;

        debug ("Binding window title to file_name");
        bind_property ("file_name", this, "title");
        debug ("Success!");

        open_file (file);

        debug ("Connecting signals");
        // Signal callbacks are heavily derived from similar operations in
        // elementary/code
        save_as_button.clicked.connect (on_save_as);
        this.close_request.connect (on_close);
        buf.changed.connect (on_buffer_changed);

    }


    /* ---------------- FILE OPERATIONS ---------------- */
    public void open_file (File file = this.file) {
        debug ("Attempting to open file %s", file.get_basename ());

        try {
            var distream = new DataInputStream (file.read (null));
            var contents = distream.read_upto ("", -1, null);
            buf.set_text (contents ?? "");

            this.file = file;
            this.file_name = file.get_basename ();
            header.tooltip_text = file.get_path ();

        } catch (Error err) {
            warning ("Couldn't open file: %s", err.message);
        }
    }

    public void save_file (File file = this.file) {
        if (Application.data_dir_path in this.file.get_path ()) {
            Utils.check_if_data_dir ();
        }

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

    /* ---------------- HANDLERS ---------------- */
    public void on_save_as () {
        debug ("Save event!");

        File oldfile = this.file;
        bool is_unsaved_doc = (Application.data_dir_path in this.file.get_path ());

        var all_files_filter = new Gtk.FileFilter () {
            name = _("All files"),
        };
        all_files_filter.add_pattern ("*");

        var text_files_filter = new Gtk.FileFilter () {
            name = _("Text files"),
        };
        text_files_filter.add_mime_type ("text/plain");

        var filter_model = new ListStore (typeof (Gtk.FileFilter));
        filter_model.append (all_files_filter);
        filter_model.append (text_files_filter);

        var save_dialog = new Gtk.FileDialog () {
            default_filter = text_files_filter,
            filters = filter_model,
            modal = true,
            title = _("Save as"),
            initial_name = (is_unsaved_doc ? file_name + ".txt" : file_name)
        };

        save_dialog.save.begin (this, null, (obj, res) => {
            try {

                file = save_dialog.save.end (res);
                save_file (file);

                this.file = file;
                file_name = file.get_basename ();
                header.tooltip_text = file.get_path ();

                if ((is_unsaved_doc) && (oldfile != file)) {
                    oldfile.delete ();
                }

            } catch (Error err) {
                    warning ("Failed to save file: %s", err.message);
            }
        });

    }

    public void on_buffer_changed () {
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

    }

    public bool on_close () {
        debug ("Close event!");

        bool is_unsaved_doc = (Application.data_dir_path in this.file.get_path ());

        // We want to delete empty unsaved documents
        if ((is_unsaved_doc) && (buf.text == "")) {

            try {
                this.file.delete ();

            } catch (Error err) {
                    warning ("Failed to delete empty temp file: %s", err.message);
            }

        } else {
            save_file ();
        }

        return false;
    }
}

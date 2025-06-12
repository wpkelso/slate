/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */

public class AppWindow : Gtk.Window {
    public File file { get; set; }
    private Gtk.TextBuffer buf;
    private Gtk.EditableLabel header_label;
    public string file_name;

    // Add a debounce so we aren't writing the entire buffer every character input
    public int interval = 500; // ms
    public uint debounce_timer_id = 0;

    // We need to track this for specific cases
    public bool is_unsaved_doc = false;


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
                    {"<Control>s"},
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

        header_label = new Gtk.EditableLabel () {
            xalign = 0.5f,
            text = ""
        };

        header.title_widget = header_label;

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

        debug ("Connecting signals");

        // Signal callbacks are heavily derived from similar operations in
        // elementary/code
        save_as_button.clicked.connect (on_save_as);
        this.close_request.connect (on_close);
        buf.changed.connect (on_buffer_changed);

        debug ("Binding window title to file_name");

        // Window title, and header label, are file name
        // We dont want to rename files with no save location yet
        // 
        file.bind_property ("file_name", this, "title");
        file.bind_property ("file_name", header_label, "text");
        bind_property ("is_unsaved_doc", header_label, "sensitive", Glib.BindingFlags.INVERT_BOOLEANS);

        debug ("Success!");

        // We want to open the file in a new window when people drop files on this
        var drop_target = new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY);
        this.add_controller (drop_target);

        //TODO: Proper handler
        drop_target.drop.connect ((target, value, x, y) => {
            debug ("Drop event!");
            if (value.type () == typeof (Gdk.FileList)) {
                var list = (Gdk.FileList)value;

                File[] file_array = {};
                foreach (unowned var files in list.get_files ()) {
                    file_array += files;
                }

                Application.open (file_array);
                return true;
            }
            return false;
        });

        open_file (file);
    }


    /* ---------------- FILE OPERATIONS ---------------- */
    public void open_file (File file = this.file) {

        debug ("Attempting to open file %s", file.get_basename ());
        try {
            var distream = new DataInputStream (file.read (null));
            var contents = distream.read_upto ("", -1, null);

            buf.set_text (contents);
            this.file = file;
            this.is_unsaved_doc = (Environment.get_user_data_dir () in this.file.get_path ());
            this.header_label.tooltip_markup.text = this.file.get_path ();
            this.file_name = file.get_basename ();

        } catch (Error err) {
            warning ("Couldn't open file: %s", err.message);
        }
    }

    public void save_file (File file = this.file) {

        // Check if datadir still there, recreate it if not
        // So we prevent data loss in the event the user deletes everything during use
        if (is_unsaved_doc) {
            Application.check_if_datadir ();
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
        var save_dialog = new Gtk.FileDialog () { initial_name = this.file.basename () };
        File oldfile = this.file;

        save_dialog.save.begin (this, null, (obj, res) => {
            try {

                file = save_dialog.save.end (res);
                save_file (file);

                // Only do after the operation, so we do not set this.file to something fucky
                this.file = file;
                this.file_name = file.get_basename ();

                if ((unsaved_doc) && (oldfile != file)) {
                    oldfile.delete ();
                }
                this.is_unsaved_doc = (Environment.get_user_data_dir () in this.file.get_path ());


            } catch (Error err) {
                    warning ("Failed to save file: %s", err.message);
            }
        });


    }

    private void on_buffer_changed () {
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

    private bool on_close () {
        debug ("Close event!");

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

    private void on_title_changed () {
        debug ("Renaming event!");

        try {
            this.file.move (header_label, File.CopyFlags.None);
            this.file_name = this.file.get_basename ();

        } catch (Error err) {
            warning ("Failed to rename: %s", err.message);
        }

    }
}

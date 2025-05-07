public class AppWindow : Gtk.Window {
    public File file { get; set; }
    private Gtk.TextBuffer buf;
    public string file_name { get; set; }

    public signal void request_new ();

    public AppWindow () {
        debug ("Constructing GUI");

        var new_button = new Gtk.Button.from_icon_name ("document-new");
        var open_button = new Gtk.Button.from_icon_name ("document-open");
        var save_as_button = new Gtk.Button.from_icon_name ("document-save-as");

        var actions_box = new Granite.Box (HORIZONTAL, HALF);
        actions_box.append(new_button);
        actions_box.append(open_button);
        actions_box.append(save_as_button);


        var header = new Gtk.HeaderBar () {
            show_title_buttons = false
        };
        header.add_css_class (Granite.STYLE_CLASS_FLAT);
        header.pack_start (new Gtk.WindowControls (Gtk.PackType.START));
        header.pack_start (actions_box);
        header.pack_end (new Gtk.WindowControls (Gtk.PackType.END));

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
        
        var app_box = new Granite.Box (VERTICAL);
        app_box.append (header);
        app_box.append (scrolled_view);
            

        child = app_box;
        default_height = 400;
        default_width = 300;
        titlebar = new Gtk.Grid () { visible = false };

        debug ("Connecting signals");

        new_button.clicked.connect (() => {
            debug ("Requesting new window");
            request_new ();
        });

        open_button.clicked.connect (() => {
            var open_dialog = new Gtk.FileDialog ();

            open_dialog.open.begin (this, null, (obj, res) => {
                try {
                    file = open_dialog.open.end (res);
                    open_file (file);
                } catch (Error err) {
                    warning ("Failed to select file to open: %s", err.message);
                }
            });
        });

        save_as_button.clicked.connect (() => {
            var save_dialog = new Gtk.FileDialog () { initial_name = file_name};

            save_dialog.save.begin (this, null, (obj, res) => {
                try {
                    file = save_dialog.save.end (res);
                    file_name = file.get_basename ();
                    save_file (file);
                } catch (Error err) {
                    warning ("Failed to save file: %s", err.message);
                }
            });
        });

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

        file_name = "unknown"; // Initialize file_name so we don't crash when we bind it
        bind_property ("file_name", this, "title");
        debug ("Success!");

        this.close_request.connect (() => {
            save_file ();

            var backup = File.new_for_path (this.file.get_path () + "~");
            try {
                backup.delete ();
            } catch (Error err) {
                warning ("Couldn't delete the backup file: %s", err.message);
            }

            return false;
        });
    }

    public void open_file (File file = this.file) {
        this.file = file;
        debug ("Attempting to open file %s", file.get_basename ());
        try {
            file_name = file.get_basename ();
            var distream = new DataInputStream (file.read (null));
            var contents = distream.read_upto ("", -1, null);
            buf.set_text (contents);
        } catch (Error err) {
            warning ("Couldn't open file: %s", err.message);
        }

    }

    public void save_file (File file = this.file) {
        try {
            debug ("Attempting to save the buffer to disk..");
            DataOutputStream dostream;
            dostream = new DataOutputStream (
                    file.replace (
                        null,
                        true,
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

public class AppWindowFactory {
    public AppWindow create_with_file (File file) {
        var window = new AppWindow ();
        window.open_file (file);
        return window;
    }

    public AppWindow create () {
        return new AppWindow ();
    }
}

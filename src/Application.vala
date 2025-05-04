/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */

public class Application : Gtk.Application {
    private File file;
    private Gtk.TextBuffer buf;
    public string file_name { get; set; }

    public Application () {
        Object (
            application_id: "io.github.wpkelso.slate",
            flags: ApplicationFlags.DEFAULT_FLAGS
        );
    }


    public override void startup () {
        Granite.init ();
        base.startup ();
    }


    protected override void activate () {
        var open_button = new Gtk.Button.from_icon_name ("document-open");
        var new_button = new Gtk.Button.from_icon_name ("document-new");
        var save_as_button = new Gtk.Button.from_icon_name ("document-save-as");

        var actions_box = new Granite.Box (HORIZONTAL, HALF);
        actions_box.append(open_button);
        actions_box.append(new_button);
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
            

        var window = new Gtk.Window () {
            child = app_box,
            default_height = 650,
            default_width = 600,
            titlebar = new Gtk.Grid () { visible = false },
            title = "New Document"
        };


        open_button.clicked.connect (() => {
            var open_dialog = new Gtk.FileDialog ();

            open_dialog.open.begin (window, null, (obj, res) => {
                try {
                    file = open_dialog.open.end (res);

                    file_name = file.get_basename ();
                    var distream = new DataInputStream (file.read (null));
                    var contents = distream.read_upto ("", -1, null);
                    buf.set_text (contents);
                } catch (Error err) {
                    warning ("Failed to select file to open: %s", err.message);
                }
            });
        });

        save_as_button.clicked.connect (() => {
            var save_dialog = new Gtk.FileDialog () { initial_name = file_name};

            save_dialog.save.begin (window, null, (obj, res) => {
                try {
                    file = save_dialog.save.end (res);
                    file_name = file.get_basename ();

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
                    warning ("Failed to save file: %s", err.message);
                }
            });
        });

        bind_property ("file_name", window, "title");
        file_name = "New Document";

        add_window (window);
        window.show ();
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */


const string APP_ID = "io.github.wpkelso.slate";

public class Application : Gtk.Application {

    public static uint created_documents = 1;
    public static string data_dir_path = Environment.get_user_data_dir () + "/slate";


    public Application () {
        Object (
                application_id: APP_ID,
                flags: ApplicationFlags.DEFAULT_FLAGS | ApplicationFlags.HANDLES_OPEN
        );
    }

    public override void startup () {
        Granite.init ();
        base.startup ();

        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = (
                                                          granite_settings.prefers_color_scheme == DARK
        );

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = (
                                                              granite_settings.prefers_color_scheme == DARK
            );
        });

        SimpleAction new_document_action = new SimpleAction ("new-document",null);
        set_accels_for_action ("app.new-document", {"<Control>n"});
        new_document_action.activate.connect (on_new_document);
        this.add_action (new_document_action);

        SimpleAction open_document_action = new SimpleAction ("open-document",null);
        set_accels_for_action ("app.open-document", {"<Control>o"});
        open_document_action.activate.connect (on_open_document);
        this.add_action (open_document_action);

        SimpleAction saveas_action = new SimpleAction ("saveas", null);
        set_accels_for_action ("app.saveas", {"<Control><Shift>s"});
        add_action (saveas_action);
        saveas_action.activate.connect (() => {
            unowned var window = this.get_active_window () as AppWindow;
            if (window == null) {
                return;
            }

            window.on_save_as ();
        });

        SimpleAction quit_action = new SimpleAction ("quit", null);
        set_accels_for_action ("app.quit", {"<Control>q"});
        add_action (quit_action);
        quit_action.activate.connect (() => {
            foreach (var window in this.get_windows ()) {
                window.close_request ();
            }
            this.quit ();
        });

        debug ("Datadir path: %s", data_dir_path);
    }

    protected override void activate () {

        // Reopen all the unsaved documents we have in datadir
        Utils.check_if_data_dir ();

        try {
            var pile_unsaved_documents = Dir.open (data_dir_path);

            string? unsaved_doc = null;
            while ((unsaved_doc = pile_unsaved_documents.read_name ()) != null) {
                print (unsaved_doc);
                string path = Path.build_filename (data_dir_path, unsaved_doc);
                File file = File.new_for_path (path);

                bool ret = open_file (file);
                if (!ret) {
                    continue;
                }

                created_documents++;
            }

        } catch (Error e) {
            warning ("Cannot read datadir! Is the disk okay? %s\n", e.message);
        }

        // What if there was none ? The loop wouldnt happen at all.
        if (created_documents == 1) {
            on_new_document ();
        }

    }

    protected override void open (File[] files, string hint) {
        foreach (var file in files) {
            debug ("Creating window with file: %s", file.get_basename ());
            open_window_with_file (file);
        }
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }

    /* ---------------- HANDLERS ---------------- */
    public void on_new_document () {

        var name = Utils.get_new_document_name ();
        var path = Path.build_filename (Environment.get_user_data_dir (), name);
        var file = File.new_for_path (path);

        Utils.check_if_data_dir ();

        try {
            file.create_readwrite (GLib.FileCreateFlags.REPLACE_DESTINATION);

        } catch (Error e) {
            warning ("Failed to prepare target file %s\n", e.message);
        }

        open_file (file);

    }

    public bool open_window_with_file (File file) {
        if (file.query_file_type (FileQueryInfoFlags.NONE) != FileType.REGULAR) {
            warning ("Couldn't open, not a regular file.");
            return false;
        }

        var new_window = new AppWindow (file);
        add_window (new_window);
        new_window.present ();
        return true;
    }

    public void on_open_document () {
        var open_dialog = new Gtk.FileDialog ();
        open_dialog.open.begin (this.active_window, null, (obj, res) => {
            try {
                var file = open_dialog.open.end (res);
                open_window_with_file (file);
            } catch (Error err) {
                warning ("Failed to select file to open: %s", err.message);
            }
        });
    }
}

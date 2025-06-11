/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */


const string APP_ID = "io.github.wpkelso.slate";

public class Application : Gtk.Application {

    public static uint created_documents = 1;

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

        SimpleAction new_document_action = new SimpleAction (
                                                             "new-document",
                                                             null
        );
        new_document_action.activate.connect (on_new_document);
        this.add_action (new_document_action);

        SimpleAction open_document_action = new SimpleAction (
                                                              "open-document",
                                                              null
        );
        open_document_action.activate.connect (on_open_document);
        this.add_action (open_document_action);
    }

    protected override void activate () {

        // Reopen all the unsaved documents we have in datadir
        check_if_datadir ();
        var datadir = Environment.get_user_data_dir ();
        try {
            var pile_unsaved_documents = Dir.open (datadir);

            string? unsaved_doc = null;
		    while ((unsaved_doc = pile_unsaved_documents.read_name ()) != null) {
                print (unsaved_doc);
                string path = Path.build_filename (datadir, unsaved_doc);
                File file = File.new_for_path (path);
                open_file (file);
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
            open_file (file);
        }
    }

    string get_new_document_name () {
        var name = _("New Document");
        if (created_documents > 1) {
            name = name + " " + created_documents.to_string ();
        }

        debug ("New document name is: %s",name);

        created_documents++;

        return name;
    }

    public void check_if_datadir () {
        debug ("do we have a data directory?");
        var data_directory = File.new_for_path (Environment.get_user_data_dir ());
        try {
            if (!data_directory.query_exists ()) {
                data_directory.make_directory ();
            }
        } catch (Error e) {
            warning ("Failed to prepare target data directory %s\n", e.message);
        }
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }

    public void on_new_document () {
        var name = get_new_document_name ();
        var path = Path.build_filename (Environment.get_user_data_dir (), name);
        var file = File.new_for_path (path);

        check_if_datadir ();
        try {
            file.create_readwrite (GLib.FileCreateFlags.REPLACE_DESTINATION);
        } catch (Error e) {
            warning ("Failed to prepare target file %s\n", e.message);
        }

        open_file (file);

    }

    public void open_file (File file) {
        var new_window = new AppWindow (file);
        add_window (new_window);
        new_window.present ();
    }

    public void on_open_document() {
        var open_dialog = new Gtk.FileDialog ();
        open_dialog.open.begin (this.active_window, null, (obj, res) => {
            try {
                var file = open_dialog.open.end (res);
                open_file (file);
            } catch (Error err) {
                warning ("Failed to select file to open: %s", err.message);
            }
        });
    }
}

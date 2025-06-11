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

        new_document_action.activate.connect (() => {
            var name = get_new_document_name ();
            var path = Path.build_filename (Environment.get_user_data_dir (), name);
            var file = File.new_for_path (path);
            debug (
                   "Document is unsaved, creating an save location at: %s",
                   path
            );

            var new_window = new AppWindow () {
                is_new = true,
            };
            new_window.open_file (file);

            debug ("Created new window with name %s", name);
            add_window (new_window);
            new_window.present ();
        });
        this.add_action (new_document_action);

        SimpleAction open_document_action = new SimpleAction (
                                                              "open-document",
                                                              null
        );
        open_document_action.activate.connect (() => {
            var open_dialog = new Gtk.FileDialog ();
            var new_window = new AppWindow ();

            open_dialog.open.begin (new_window, null, (obj, res) => {
                try {
                    var file = open_dialog.open.end (res);
                    new_window.open_file (file);
                    add_window (new_window);
                    new_window.present ();
                } catch (Error err) {
                    warning ("Failed to select file to open: %s", err.message);
                }
            });
        });
        this.add_action (open_document_action);
    }

    protected override void activate () {

        Slate.Utils.check_if_datadir ();
        saved_unsaved_documents = Environment.get_user_data_dir ();
        pile_unsaved_documents = saved_unsaved_documents.open ();

        // Conveniently, if there is no unsaved document, we just get NULL
        // Which AppWindow will process as a new unsaved doc
        foreach (unsaved_document in pile_unsaved_documents.read_name() ) {

            debug (
                "Document is unsaved, creating an save location at: %s",
                path
            );

            var new_window = new AppWindow (unsaved_document) {
                is_new = true,
            };

            add_window (new_window);
            new_window.present ();
        }


        if (args[1] != null) {
            
            open_at = File.new_for_path(args[1]);
            var new_window = new AppWindow (open_at);

            add_window (new_window);
            new_window.present ();
        }
    }

    protected override void open (File[] files, string hint) {
        foreach (var file in files) {
            debug ("Creating window with file: %s", file.get_basename ());
            var window = new AppWindow ();
            window.open_file (file);

            debug ("Adding new window to application");
            add_window (window);
            window.present ();
        }
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */

public class Application : Gtk.Application {

    public Application () {
        Object (
            application_id: "io.github.wpkelso.slate",
            flags: ApplicationFlags.DEFAULT_FLAGS | ApplicationFlags.HANDLES_OPEN
        );

        SimpleAction new_document_action = new SimpleAction (
            "new-document",
            null
        );
        new_document_action.activate.connect (() => {
            debug ("Creating new window as requested");
            var new_window = new AppWindow () {file_name = "New Document"};

            add_window (new_window);
            new_window.show ();
        });
        this.add_action (new_document_action);
    }

    public override void startup () {
        Granite.init ();
        base.startup ();
    }

    protected override void activate () {
        var window = new AppWindow () { file_name = "New Document"};
        add_window (window);
        window.show ();

    }

    protected override void open (File[] files, string hint) {
        foreach (var file in files) {
            debug ("Creating window with file: %s", file.get_basename ());
            var window = new AppWindow ();
            window.open_file (file);

            debug ("Adding new window to application");
            add_window (window);
            window.show ();
        }
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}

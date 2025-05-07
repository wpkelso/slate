/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */

public class Application : Gtk.Application {
    private AppWindowFactory window_factory;
    private List<AppWindow> window_list;

    public Application () {
        Object (
            application_id: "io.github.wpkelso.slate",
            flags: ApplicationFlags.DEFAULT_FLAGS | ApplicationFlags.HANDLES_OPEN
        );
    }

    public override void startup () {
        Granite.init ();
        base.startup ();

        window_list = new List<AppWindow> ();

        this.window_added.connect (() => {
            update_new_listeners ();
        });

        this.window_removed.connect (() => {
            update_new_listeners ();
        });

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

    private void new_request_callback () {
        debug ("Creating new window as requested");
        var new_window = window_factory.create ();
        new_window.file_name = "New Document";

        window_list.append (new_window);
        add_window (new_window);
        new_window.show ();
    }

    private void update_new_listeners () {
        debug ("Updating new window request listeners");
        foreach (var window in window_list) {
            window.request_new.connect (() => {
                debug("Running window callback");
                new_request_callback ();
            });
        }
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}

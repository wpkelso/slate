/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */

public class UndoRedoButtons : Gtk.Box {

    public Gtk.TextBuffer buffer {get; construct;}

    public UndoRedoButtons (Gtk.TextBuffer buffer) {
        Object (buffer: buffer);
    }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 0;

        var undo = new Gtk.Button.from_icon_name ("edit-undo") {
            tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>Z"},
                _("Undo last change")
            )
        };
        append (undo);

        var redo = new Gtk.Button.from_icon_name ("edit-redo") {
            tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl><Shift>Z"},
                _("Redo last change")
            )
        };
        append (redo);

        add_css_class (Granite.STYLE_CLASS_LINKED);

        undo.clicked.connect (buffer.undo);
        redo.clicked.connect (buffer.redo);

        buffer.bind_property ("can_undo",
            undo, "sensitive",
            GLib.BindingFlags.SYNC_CREATE);

        buffer.bind_property ("can_redo",
            redo, "sensitive",
            GLib.BindingFlags.SYNC_CREATE);

    }
}

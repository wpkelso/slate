/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */

public class CutCopyPasteButtons : Gtk.Box {

    public Gtk.TextView textview {get; construct;}

    public CutCopyPasteButtons (Gtk.TextView textview) {
        Object (textview: textview);
    }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 0;

        var cut = new Gtk.Button.from_icon_name ("edit-cut") {
            tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>X"},
                _("Cut selected text")
            )
        };

        var copy = new Gtk.Button.from_icon_name ("edit-copy") {
            tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>C"},
                _("Copy selected text")
            )
        };

        var paste = new Gtk.Button.from_icon_name ("edit-paste") {
            tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>V"},
                _("Paste from clipboard")
            )
        };

        append (cut);
        append (copy);
        append (paste);

        add_css_class (Granite.STYLE_CLASS_LINKED);

        cut.clicked.connect (() => {textview.cut_clipboard ();});
        copy.clicked.connect (() => {textview.copy_clipboard ();});
        paste.clicked.connect (() => {textview.paste_clipboard ();});
    }
}

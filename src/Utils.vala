/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 William Kelso <wpkelso@posteo.net>
 */

 namespace Utils {

    public string get_new_document_name () {
        var name = _("New Document");

        if (Application.created_documents > 1) {
            name = name + " " + Application.created_documents.to_string ();
        }

        debug ("New document name is: %s", name);

        Application.created_documents++;

        return name;
    }

    public static void check_if_datadir () {
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
 }

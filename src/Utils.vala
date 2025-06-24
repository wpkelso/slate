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

    public static void check_if_data_dir () {
        debug ("Do we have a data directory?");
        var data_directory = File.new_for_path (Application.data_dir_path);
        try {
            if (!data_directory.query_exists ()) {
                data_directory.make_directory ();
                debug ("No, creating data directory");
            } else {
                debug ("Yes, data directory exists!");
            }
        } catch (Error err) {
            warning ("Failed to prepare target data directory %s\n", err.message);
        }
    }

    public static bool check_if_valid_text_file (File file) {
        try {
            FileInfo info = file.query_info ("*", NOFOLLOW_SYMLINKS);

            var content_type = info.get_content_type (); 
            if (info.get_file_type () == FileType.REGULAR && 
                    ContentType.is_a (content_type, "text/*") || 
                    ContentType.is_a (content_type, "application/x-zerosize")
               ) { 
                return true;
            }

        } catch (Error err) {
            warning ("Failed to get file information: %s", err.message);
        }


        return false;
    }
 }

using Gee;
using Gtk;

[GtkTemplate (ui = "/org/xnsc/gnotebook/gnotebook.ui")]
public class GN.Window : ApplicationWindow {
    public Window (Gtk.Application app) {
		Object (application: app);
		setup_pages_view ();
	}

	static construct {
		add_shortcut (new Shortcut (
						  ShortcutTrigger.parse_string ("<Control>Z"),
						  new CallbackAction (do_undo_shortcut)));
		add_shortcut (new Shortcut (
						  ShortcutTrigger.parse_string ("<Control><Shift>Z"),
						  new CallbackAction (do_redo_shortcut)));
	}

	private HashMap<string, Page> pages = new HashMap<string, Page> ();
	private NotebookReader? reader;
	private File? file;
	private Page? current_page;

	[GtkChild]
	private unowned TreeView pages_view;

	[GtkChild]
	private unowned ScrolledWindow page_window;

	[GtkCallback]
	private void new_book_clicked (Button button) {
		print ("New book\n");
	}

	[GtkCallback]
	private void new_clicked (Button button) {
	    var model = pages_view.get_model () as Gtk.ListStore;
		TreeIter iter;
		var prefix = "New page";
		var name = prefix;
		var suffix = 0;
		while (name_exists (name)) {
			suffix++;
			name = prefix + " " + suffix.to_string ();
		}
		model.append (out iter);
		model.set (iter, 0, name);
		pages.set (name, new Page ());
		set_page (iter);
		reader?.do_insert (name);
	}

	[GtkCallback]
	private void open_clicked (Button button) {
		var dialog = new FileChooserDialog ("Open Notebook", this,
											FileChooserAction.SELECT_FOLDER,
											"Cancel", ResponseType.CANCEL,
											"Open", ResponseType.ACCEPT, null);
		dialog.set_create_folders (false);
		dialog.show ();
		dialog.response.connect (on_open_response);
	}

	[GtkCallback]
	private void save_clicked (Button button) {
		if (file == null) {
			var dialog = new FileChooserDialog ("Save As", this,
												FileChooserAction.SELECT_FOLDER,
												"Cancel", ResponseType.CANCEL,
												"Save", ResponseType.ACCEPT,
												null);
			dialog.set_create_folders (true);
			dialog.show ();
			dialog.response.connect (on_save_response);
		}
		else {
			save_notebook ();
		}
	}

	[GtkCallback]
	private void undo_clicked (Button button) {
		current_page?.do_undo ();
	}

	[GtkCallback]
	private void redo_clicked (Button button) {
		current_page?.do_redo ();
	}

	[GtkCallback]
	private void insert_text (Button button) {
		if (current_page != null) {
			current_page.insert_text ();
		}
	}

	[GtkCallback]
	private void insert_image (Button button) {
		if (current_page != null) {
			current_page.insert_image (this);
		}
	}

	[GtkCallback]
	private void insert_video (Button button) {
		if (current_page != null) {
			current_page.insert_video (this);
		}
	}

	[GtkCallback]
	private void rename_page (Button button) {
		if (pages_view.get_selection ().get_selected (null, null)) {
			var dialog = new RenameDialog (this);
			dialog.set_modal (true);
			dialog.set_transient_for (this);
			dialog.show ();
		}
	}

	[GtkCallback]
	private void delete_page (Button button) {
		var model = pages_view.get_model () as Gtk.ListStore;
		TreeIter iter;
		if (pages_view.get_selection ().get_selected (null, out iter)) {
			string name;
			model.get (iter, 0, out name);
			if (current_page == pages.get (name)) {
				current_page = null;
				page_window.set_child (null);
			}
			pages.unset (name);
			reader.do_delete (name);
			model.remove (ref iter);
		}
	}

	[GtkCallback]
	private void move_up (Button button) {
		var model = pages_view.get_model () as Gtk.ListStore;
		TreeIter iter;
		if (pages_view.get_selection ().get_selected (null, out iter)) {
			TreeIter prev = iter.copy ();
			if (model.iter_previous (ref prev)) {
				model.move_before (ref iter, prev);
			}
		}
	}

	[GtkCallback]
	private void move_down (Button button) {
		var model = pages_view.get_model () as Gtk.ListStore;
		TreeIter iter;
		if (pages_view.get_selection ().get_selected (null, out iter)) {
			TreeIter next = iter.copy ();
			if (model.iter_next (ref next)) {
				model.move_after (ref iter, next);
			}
		}
	}

	[GtkCallback]
	private void select_page (TreeView view, TreePath path,
							  TreeViewColumn? column) {
		var model = pages_view.get_model ();
		TreeIter iter;
		if (model.get_iter (out iter, path)) {
			set_page (iter);
		}
	}

	private void setup_pages_view () {
		var model = new Gtk.ListStore (1, typeof (string));
		pages_view.set_model (model);
		var renderer = new CellRendererText ();
		pages_view.insert_column_with_attributes (-1, "Pages", renderer,
												  "text", 0);
	}

	private void set_page (TreeIter iter) {
		var model = pages_view.get_model () as Gtk.ListStore;
		string name;
		model.get (iter, 0, out name);
		current_page = pages.get (name);
		if (current_page == null) {
			var page = new Page ();
			var alloc = Allocation ();
			page_window.get_allocation (out alloc);
			var page_width = alloc.width - page.margin_start - page.margin_end;
			try {
				reader.read_page (page, page_width, name);
			} catch (NBError.NO_PAGE e) {
			} catch (Error e) {
				var dialog =
					new MessageDialog (this, DialogFlags.DESTROY_WITH_PARENT,
									   MessageType.ERROR, ButtonsType.CLOSE,
									   "Error opening page");
				dialog.secondary_text = e.message;
				dialog.show ();
				dialog.response.connect (dialog.destroy);
				return;
			}
			pages.set (name, page);
			current_page = page;
		}
		page_window.set_child (current_page);
	}

	private void on_open_response (Dialog source, int response_id) {
		if (response_id == ResponseType.ACCEPT) {
			var chooser = source as FileChooser;
			file = chooser.get_file ();
			open_notebook ();
		}
		source.destroy ();
	}

	private void on_save_response (Dialog source, int response_id) {
		if (response_id == ResponseType.ACCEPT) {
			var chooser = source as FileChooser;
			file = chooser.get_file ();
			save_notebook ();
		}
		source.destroy ();
	}

	private void open_notebook () {
		var model = pages_view.get_model () as Gtk.ListStore;
		model.clear ();
		pages.clear ();
		try {
		    reader = new NotebookReader (file);
			TreeIter iter;
			foreach (string name in reader.page_names ()) {
				model.append (out iter);
				model.set (iter, 0, name);
			}
			current_page = null;
			page_window.set_child (null);
		} catch (Error e) {
			model.clear ();
			var dialog =
				new MessageDialog (this, DialogFlags.DESTROY_WITH_PARENT,
								   MessageType.ERROR, ButtonsType.CLOSE,
								   "Error opening notebook");
			dialog.secondary_text = e.message;
			dialog.show ();
			dialog.response.connect (dialog.destroy);
		}
	}

	private void save_notebook () {
		try {
			reader?.sync ();
			var writer = new NotebookWriter (file);
			var names = new ArrayList<string> ();
			var model = pages_view.get_model ();
			TreeIter iter;
			if (model.get_iter_first (out iter)) {
				do {
					string name;
					model.get (iter, 0, out name);
					names.add (name);
				} while (model.iter_next (ref iter));
			}
			writer.write_toc (names);
			foreach (Map.Entry<string, Page> entry in pages) {
				if (entry.value.modified ()) {
					writer.write_page (entry.key, entry.value);
				}
			}
		} catch (Error e) {
			var dialog =
				new MessageDialog (this, DialogFlags.DESTROY_WITH_PARENT,
								   MessageType.ERROR, ButtonsType.CLOSE,
								   "Error saving notebook");
			dialog.secondary_text = e.message;
			dialog.show ();
			dialog.response.connect (dialog.destroy);
		}
	}

	private static bool do_undo_shortcut (Widget widget) {
		var window = widget as GN.Window;
		window.current_page?.do_undo ();
		return true;
	}

	private static bool do_redo_shortcut (Widget widget) {
		var window = widget as GN.Window;
		window.current_page?.do_redo ();
		return true;
	}

	internal void open_file (File file) {
		this.file = file;
		open_notebook ();
	}

	internal bool name_exists (string name) {
		var model = pages_view.get_model () as Gtk.ListStore;
		TreeIter iter;
		if (model.get_iter_first (out iter)) {
			do {
				string item_name;
				model.get (iter, 0, out item_name);
				if (name == item_name) {
					return true;
				}
			} while (model.iter_next (ref iter));
		}
		return false;
	}

	internal void do_rename (string new_name) {
		var model = pages_view.get_model () as Gtk.ListStore;
		TreeIter iter;
		if (pages_view.get_selection ().get_selected (null, out iter)) {
			string old_name;
			model.get (iter, 0, out old_name);
			reader?.do_rename (old_name, new_name);
			model.set (iter, 0, new_name);
			var page = pages.get (old_name);
			pages.unset (old_name);
			pages.set (new_name, page);
		}
	}
}
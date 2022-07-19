using Gtk;

[GtkTemplate (ui = "/org/xnsc/gnotebook/gnotebook.ui")]
public class GN.Window : ApplicationWindow {
    public Window (Gtk.Application app) {
		Object (application: app);
		setup_pages_view ();
	}

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
	}

	[GtkCallback]
	private void open_clicked (Button button) {
		print ("Open\n");
	}

	[GtkCallback]
	private void save_clicked (Button button) {
		print ("Save\n");
	}

	[GtkCallback]
	private void undo_clicked (Button button) {
		print ("Undo\n");
	}

	[GtkCallback]
	private void redo_clicked (Button button) {
		print ("Redo\n");
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
			model.remove (ref iter);
		}
	}

	[GtkCallback]
	private void select_page (TreeView view, TreePath path,
							  TreeViewColumn? column) {
		print ("Clicked page\n");
	}

	private void setup_pages_view () {
		var model = new Gtk.ListStore (1, typeof (string));
		pages_view.set_model (model);
		var renderer = new CellRendererText ();
		pages_view.insert_column_with_attributes (-1, "Pages", renderer,
												  "text", 0);
	}

	internal bool name_exists (string name) {
		var model = pages_view.get_model () as Gtk.ListStore;
		TreeIter iter;
		if (model.get_iter_first (out iter)) {
			do {
				string item_name;
				model.get (iter, 0, out item_name, -1);
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
			model.set (iter, 0, new_name, -1);
		}
	}
}
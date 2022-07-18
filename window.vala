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
		print ("New\n");
	    var model = pages_view.get_model () as Gtk.ListStore;
		TreeIter iter;
		model.append (out iter);
		model.set (iter, 0, "New page");
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
		print ("Rename\n");
	}

	[GtkCallback]
	private void delete_page (Button button) {
		print ("Delete\n");
	}

	[GtkCallback]
	private void select_page (TreeView view, TreePath path,
							  TreeViewColumn? column) {
		print("Clicked page\n");
	}

	private void setup_pages_view () {
		var model = new Gtk.ListStore (1, typeof (string));
		pages_view.set_model (model);
		var renderer = new CellRendererText ();
		pages_view.insert_column_with_attributes (-1, "Pages", renderer,
												  "text", 0);
	}
}
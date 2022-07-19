using Gee;
using Gtk;

[GtkTemplate (ui = "/org/xnsc/gnotebook/gnotebook.ui")]
public class GN.Window : ApplicationWindow {
    public Window (Gtk.Application app) {
		Object (application: app);
		setup_pages_view ();
	}

	private ArrayList<Page> pages = new ArrayList<Page> ();
	private Page current_page;

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
		pages.add (new Page ());
		set_page (iter);
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
	private void insert_text (Button button) {
		if (current_page != null) {
			current_page.insert_text ();
		}
	}

	[GtkCallback]
	private void insert_image (Button button) {
		if (current_page != null) {
			current_page.insert_image ();
		}
	}

	[GtkCallback]
	private void insert_video (Button button) {
		if (current_page != null) {
			current_page.insert_video ();
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
			int index = iter_index (iter);
			if (current_page == pages.get (index)) {
				current_page = null;
				page_window.set_child (null);
			}
			pages.remove_at (index);
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
				int index = iter_index (iter);
				var temp = pages.get (index - 1);
				pages.set (index - 1, pages.get (index));
				pages.set (index, temp);
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
				int index = iter_index (iter);
				var temp = pages.get (index + 1);
				pages.set (index + 1, pages.get (index));
				pages.set (index, temp);
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

	private int iter_index (TreeIter iter) {
		var model = pages_view.get_model ();
		var path = model.get_path (iter);
		return_val_if_fail (path.get_depth () == 1, -1);
		return path.get_indices ()[0];
	}

	private void set_page (TreeIter iter) {
		int index = iter_index (iter);
		current_page = pages.get (index);
		page_window.set_child (current_page);
	}
}
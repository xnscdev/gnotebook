using Gdk;
using Gee;
using Gtk;

public class GN.Page : Box {
	public Page () {
		Object (
			orientation: Orientation.VERTICAL,
			spacing: 15,
			margin_top: 15,
			margin_bottom: 15,
			margin_start: 15,
			margin_end: 15);
	}

	private GLib.Queue<UndoItem> undo_stack = new GLib.Queue<UndoItem> ();

	public void insert_text () {
		var view = new TextView ();
		add_text (view);
	}

	public void add_text (TextView view) {
		view.wrap_mode = WrapMode.WORD;
		view.top_margin = view.bottom_margin = view.left_margin =
			view.right_margin = 10;
		view.buffer.set_enable_undo (false);
		view.insert_at_cursor.connect (do_text_insert);
		view.delete_from_cursor.connect (do_text_delete);
		append (view);
	}

	public void insert_image (Gtk.Window window) {
		var dialog = new FileChooserDialog ("Open Images", window,
											FileChooserAction.OPEN,
											"Cancel", ResponseType.CANCEL,
											"Open", ResponseType.ACCEPT,
											null);
		var filter = new FileFilter ();
		filter.add_mime_type ("image/ *");
		dialog.add_filter (filter);
		dialog.add_choice ("scale", "Scale Images", null, null);
		dialog.set_choice ("scale", "true");
		dialog.select_multiple = true;
		dialog.show ();
		dialog.response.connect (on_open_image);
	}

	public void insert_video (Gtk.Window window) {
	}

	private void on_open_image (Dialog source, int response_id) {
		if (response_id == ResponseType.ACCEPT) {
			var chooser = source as FileChooser;
			var files = chooser.get_files ();
			ImageFlags flags = 0;
			if (chooser.get_choice ("scale") == "true") {
				flags |= ImageFlags.SCALE;
			}

			try {
				var images = new ArrayList<Picture> ();
				for (int i = 0; i < files.get_n_items (); i++) {
					var file = files.get_item (i) as File;
					var texture = Texture.from_file (file);
					var image = new Picture.for_paintable (texture);
					images.add (image);
				}

				var alloc = Allocation ();
				get_allocation (out alloc);
				var page_width = alloc.width - margin_start - margin_end;
				var image = new ImageEntry (images, page_width, flags);
				append (image);
			} catch (Error e) {
				var dialog =
					new MessageDialog (null, DialogFlags.DESTROY_WITH_PARENT,
									   MessageType.ERROR, ButtonsType.CLOSE,
									   "Error opening images");
				dialog.secondary_text = e.message;
				dialog.show ();
				dialog.response.connect (dialog.destroy);
			}
		}
		source.destroy ();
	}

	private void do_text_insert (TextView source, string text) {
		print ("Insert\n");
	}

	private void do_text_delete (TextView source, DeleteType type, int count) {
		print ("Delete\n");
	}

	public bool modified () {
		return undo_stack.length != 0;
	}
}
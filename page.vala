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

	private Gee.List<UndoItem> undo_stack = new ArrayList<UndoItem> ();
	private int undo_index;
	private bool no_delete;
	private bool no_insert;

	public void insert_text () {
		var view = new TextView ();
		add_text (view);
		add_undo (new CreateEntry (view));
	}

	public void add_text (TextView view) {
		view.wrap_mode = WrapMode.WORD;
		view.top_margin = view.bottom_margin = view.left_margin =
			view.right_margin = 10;
		view.buffer.set_enable_undo (false);
		view.buffer.insert_text.connect (do_text_insert);
		view.buffer.delete_range.connect (do_text_delete);
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

	public bool modified () {
		return undo_stack.size != 0;
	}

	public void do_undo () {
		if (undo_index > 0) {
			var item = undo_stack.get (--undo_index);
			item.do_undo (this);
		}
	}

	public void do_redo () {
		if (undo_index < undo_stack.size) {
			var item = undo_stack.get (undo_index++);
			item.do_redo (this);
		}
	}

	private void do_text_insert (TextBuffer source, ref TextIter pos,
								 string text, int length) {
		if (!no_insert) {
			add_undo (new TextInsert (pos, text));
		}
	}

	private void do_text_delete (TextBuffer source, TextIter start,
								 TextIter end) {
		if (!no_delete) {
			add_undo (new TextDelete (start, end));
		}
	}

	private void add_undo (UndoItem item) {
		if (undo_index < undo_stack.size) {
			undo_stack = undo_stack.slice (0, undo_index);
		}
		undo_stack.add (item);
		undo_index++;
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
				add_undo (new CreateEntry (image));
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

	internal void mask_delete () {
		no_delete = true;
	}

	internal void unmask_delete () {
		no_delete = false;
	}

	internal void mask_insert () {
		no_insert = true;
	}

	internal void unmask_insert () {
		no_insert = false;
	}
}
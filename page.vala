using Gtk;

public class GN.Page : Box {
	public Page () {
		Object (orientation: Orientation.VERTICAL);
		margin_top = margin_bottom = margin_start = margin_end = spacing = 15;
	}

	public void insert_text () {
		var view = new TextView ();
		view.wrap_mode = WrapMode.WORD;
		view.top_margin = view.bottom_margin = view.left_margin =
			view.right_margin = 10;
		view.buffer.set_enable_undo (false);
		append (view);
	}

	public void insert_image () {
	}

	public void insert_video () {
	}
}
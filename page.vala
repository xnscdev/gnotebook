using Gtk;

public class GN.Page : Box {
	public Page () {
		Object (orientation: Orientation.VERTICAL);
		margin_top = margin_bottom = margin_start = margin_end = spacing = 15;
	}

	internal void insert_text () {
		var view = new TextView ();
		view.wrap_mode = WrapMode.WORD;
		append (view);
	}

	internal void insert_image () {
	}

	internal void insert_video () {
	}
}
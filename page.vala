using Gtk;

public class GN.Page : Box {
	public Page () {
		Object (orientation: Orientation.VERTICAL);
		margin_top = margin_bottom = margin_start = margin_end = spacing = 15;
	}

	internal void insert_text () {
		append (new TextView ());
	}

	internal void insert_image () {
	}

	internal void insert_video () {
	}
}
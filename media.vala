using Gdk;
using Gee;
using Gtk;

[Flags]
public enum GN.ImageFlags {
	SCALE
}

public class GN.ImageEntry : Box {
	public ImageEntry (ArrayList<Picture> images, int page_width,
					   ImageFlags flags)
		throws Error {
		Object (orientation: Orientation.HORIZONTAL, spacing: 15, flags: flags);
		var total_width = 0;
	    foreach (Picture image in images) {
			var texture = image.get_paintable () as Texture;
			total_width += texture.width;
		}

		page_width -= spacing * (images.size - 1);
		double scale;
		if (ImageFlags.SCALE in flags) {
			scale = (double) page_width / (double) total_width;
		} else {
			scale = 1.0;
		}

		foreach (Picture image in images) {
			var texture = image.get_paintable () as Texture;
			var scaled_width = (int) (texture.width * scale);
			var scaled_height = (int) (texture.height * scale);
			image.set_size_request (scaled_width, scaled_height);
			append (image);
		}
		this.images = images.size;
	}

	public ImageFlags flags { get; set; }
	public int images { get; private set; }
}
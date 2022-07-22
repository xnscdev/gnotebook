using Gtk;

public class GN.Application : Gtk.Application {
	public Application () {
		Object (application_id: "org.xnsc.GNotebook",
				flags: ApplicationFlags.HANDLES_OPEN);
		activate.connect (() => new GN.Window (this).present ());
		open.connect (open_files);
	}

	private void open_files (File[] files, string hint) {
		foreach (Gtk.Window window in get_windows ()) {
			window.present ();
		}
		foreach (File file in files) {
			var window = new GN.Window (this);
			window.present ();
			window.open_file (file);
		}
	}
}
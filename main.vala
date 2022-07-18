using Gtk;

int main (string[] args) {
	var app = new Gtk.Application ("org.xnsc.GNotebook",
								   ApplicationFlags.FLAGS_NONE);
	app.activate.connect (() => {
			var window = new GN.Window (app);
			window.present ();
		});
	return app.run (args);
}
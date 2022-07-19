using Gtk;

public class GN.RenameDialog : Dialog {
	private Entry name_entry;
	private Widget rename_button;
	private unowned Window window;

	public RenameDialog (Window window) {
		this.window = window;
		title = "Rename page";
		set_default_size (350, 100);
		create_widgets ();
		connect_signals ();
	}

	private void create_widgets () {
		name_entry = new Entry ();
		var rename_label = new Label.with_mnemonic ("_Rename to:");
		rename_label.mnemonic_widget = name_entry;

		var hbox = new Box (Orientation.HORIZONTAL, 20);
		hbox.append (rename_label);
		hbox.append (name_entry);
		hbox.set_spacing (20);
		hbox.margin_top = hbox.margin_start = hbox.margin_end = 6;
		hbox.margin_bottom = 10;
		var content = get_content_area () as Box;
		content.append (hbox);

		var cancel_button = add_button ("Cancel", ResponseType.CLOSE);
		cancel_button.margin_end = 6;
		rename_button = add_button ("Rename", ResponseType.APPLY);
		rename_button.sensitive = false;
		rename_button.margin_end = 6;
	}

	private void connect_signals () {
		name_entry.changed.connect (() => {
				string text = name_entry.text;
				if (text == "") {
					rename_button.sensitive = false;
				} else {
					rename_button.sensitive = !window.name_exists (text);
				}
			});
		response.connect (on_response);
	}

	private void on_response (Dialog source, int response_id) {
		if (response_id == ResponseType.APPLY) {
			window.do_rename (name_entry.text);
		}
		destroy ();
	}
}
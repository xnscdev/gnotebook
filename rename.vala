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
		var content = get_content_area () as Box;
		content.append (hbox);
		content.spacing = 10;

		add_button ("Cancel", ResponseType.CLOSE);
		rename_button = add_button ("Rename", ResponseType.APPLY);
		rename_button.sensitive = false;
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
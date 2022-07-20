using Gtk;

private enum GN.EntryType {
	TEXT,
	IMAGE,
	VIDEO
}

private struct GN.PageEntry {
	uint32 type;
	uint16 width;
	uint16 height;
	uint64 size;
	uint64 length;
}

private struct GN.FileHeader {
	char magic[4];
	uint32 version;
	uint64 page_count;
	uint64 create_time;
}

private struct GN.PageHeader {
	uint64 name_length;
	uint64 content_offset;
	uint64 entry_count;
}

private const int VERSION = 1;

public class GN.NotebookWriter {
	public NotebookWriter (File? file) throws Error {
		try {
			file.delete ();
		} catch (Error e) {}
		stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
	}

	private FileOutputStream stream;
	private ulong[] page_table;
	private ulong page_index;
	private ulong page_count;

	public void write_header (ulong page_count) throws Error {
		var header = FileHeader ();
		header.magic[0] = '*';
		header.magic[1] = 'G';
		header.magic[2] = 'N';
		header.magic[3] = 'B';
		header.version = VERSION;
		header.page_count = page_count;
		header.create_time = get_real_time () / 1000000;
		write_data ((uint8[]) header);

		page_table = new ulong[page_count];
		page_index = 0;
		this.page_count = page_count;
		stream.seek (sizeof (ulong) * page_count, SeekType.CUR);
	}

	public void write_page (string name, Page page) throws Error {
		var header = PageHeader ();
		header.name_length = name.length;
		header.content_offset = ((header.name_length - 1) | 7) + 1;
		header.entry_count = 0;

		var offset = stream.tell ();
		page_table[page_index++] = (ulong) offset;
		var entry_offset =
			offset + sizeof (PageHeader) + (int64) header.content_offset;
		stream.seek (sizeof (PageHeader), SeekType.CUR);
		write_data (name.data);
		stream.seek (entry_offset, SeekType.SET);

		for (var child = page.get_first_child (); child != null;
			 child = child.get_next_sibling (), header.entry_count++) {
			var entry = PageEntry ();
			if (child is TextView) {
				var widget = child as TextView;
				var buffer = widget.get_buffer ();
				TextIter start;
				TextIter end;
				buffer.get_bounds (out start, out end);
				var text = buffer.get_text (start, end, false);
				entry.type = EntryType.TEXT;
				entry.width = entry.height = 0;
				entry.length = text.length;
				entry.size = ((entry.length - 1) | 7) + 1;
				write_data ((uint8[]) entry);
				write_data (text.data);
				entry_offset += sizeof (PageEntry) + (int64) entry.size;
				stream.seek (entry_offset, SeekType.SET);
			}
			else {
				return_if_reached ();
			}
		}

		stream.seek (offset, SeekType.SET);
		write_data ((uint8[]) header);
		stream.flush ();
		stream.seek (entry_offset, SeekType.SET);
	}

	public void write_final () throws Error {
		stream.seek (sizeof (FileHeader), SeekType.SET);
		write_data ((uint8[]) page_table);
	}

	private void write_data (uint8[] data) throws Error {
		long written = 0;
		while (written < data.length) {
			written += stream.write (data[written:data.length]);
		}
	}
}
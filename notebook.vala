using Gdk;
using Gee;
using Gtk;

private struct GN.TOCHeader {
	uint32 magic;
	uint32 version;
	uint32 page_count;
	uint32 reserved;
	uint64 modify_time;
}

private struct GN.PageHeader {
	uint32 magic;
	uint32 entry_count;
	uint64 modify_time;
}

private enum GN.EntryType {
	TEXT,
	IMAGE,
	MEDIA
}

private struct GN.EntryHeader {
	uint32 type;
	uint32 flags;
	uint64 size;
	uint64 length;
}

private struct GN.MediaHeader {
	uint16 width;
	uint16 height;
	uint32 reserved;
	uint64 size;
	uint64 offset;
}

private const uint32 MAGIC = 0x424e472a;
private const int VERSION = 1;
private const string TOC_FILE = "TOC";

errordomain GN.NBError {
	BAD_HEADER,
    VERSION_NEW,
	NO_PAGE,
	BAD_PAGE,
	TRUNCATED_PAGE,
	MEDIA_COPY,
    BAD_ENTRY,
	BAD_WIDGET,
	TOC_UPDATE
}

private string page_path (string name) {
	return Base64.encode (name.data).replace ("/", "_").replace ("=", "-");
}

public class GN.NotebookReader {
	public NotebookReader (File dir) throws Error {
	    var toc = new DataInputStream (dir.get_child (TOC_FILE).read ());
		toc.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);
		var header = TOCHeader ();
		header.magic = toc.read_uint32 ();
		header.version = toc.read_uint32 ();
		header.page_count = toc.read_uint32 ();
		toc.skip (12);
		if (header.magic != MAGIC) {
			throw new NBError.BAD_HEADER ("Bad magic number in TOC header");
		} else if (header.version > VERSION ) {
			throw new NBError.VERSION_NEW ("Notebook version is too new");
		}
		for (var i = 0; i < header.page_count; i++) {
			string name = toc.read_line (null);
			if (name == null) {
				break;
			}
			pages.add (name);
		}
		this.dir = dir;
	}

	private File dir;
	private ArrayList<string> pages = new ArrayList<string> ();
	private HashMap<string, string> to_rename = new HashMap<string, string> ();
	private ArrayList<string> to_delete = new ArrayList<string> ();

	public void read_page (Page page, int width, string name) throws Error {
		var path = page_path (name);
		DataInputStream stream;
		try {
			stream = new DataInputStream (dir.get_child (path).read ());
		} catch (Error e) {
			throw new NBError.NO_PAGE ("Page does not exist");
		}
		stream.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);
		var header = PageHeader ();
		header.magic = stream.read_uint32 ();
		header.entry_count = stream.read_uint32 ();
		stream.skip (8);
		if (header.magic != MAGIC) {
			throw new NBError.BAD_PAGE ("Bad magic number in page header");
		}

		for (var i = 0; i < header.entry_count; i++) {
			var eh = EntryHeader ();
			eh.type = stream.read_uint32 ();
			eh.flags = stream.read_uint32 ();
			eh.size = stream.read_uint64 ();
			eh.length = stream.read_uint64 ();
			switch (eh.type) {
			case EntryType.TEXT:
				var buffer = new TextBuffer (null);
				if (eh.length > 0) {
					var data = new uint8[eh.length];
					size_t size = stream.read (data);
					if (size != eh.length) {
						throw new NBError.TRUNCATED_PAGE ("Truncated page");
					}
					stream.skip ((size_t) (eh.size - eh.length));
					data.resize ((int) (eh.length + 1));
					data[eh.length] = '\0';
					buffer.set_text ((string) data);
				}
				var widget = new TextView.with_buffer (buffer);
				page.add_text (widget);
				break;
			case EntryType.IMAGE:
				var mh = MediaHeader ();
				var images = new ArrayList<Picture> ();
				for (var j = 0; j < eh.length; j++) {
					mh.width = stream.read_uint16 ();
					mh.height = stream.read_uint16 ();
					stream.skip (4);
					mh.size = stream.read_uint64 ();
					mh.offset = stream.read_uint64 ();
					var buffer = new uint8[mh.size];
					var size = stream.read (buffer);
					if (size != mh.size) {
						throw new NBError.TRUNCATED_PAGE ("Truncated page");
					}
				    stream.skip ((size_t) (mh.offset - mh.size));
					var texture = Texture.from_bytes (new Bytes (buffer));
					var picture = new Picture.for_paintable (texture);
					images.add (picture);
				}
				var widget = new ImageEntry (images, width, eh.flags);
				page.add_image (widget);
				break;
			case EntryType.MEDIA:
				uint64 copied = 0;
				FileIOStream ios;
				var temp = File.new_tmp (null, out ios);
				var temp_stream = new DataOutputStream (ios.output_stream);
				while (copied < eh.size) {
					var to_copy = eh.size - copied;
					if (to_copy > 4096) {
						to_copy = 4096;
					}
					var buffer = new uint8[to_copy];
					var size = stream.read (buffer);
					if (size != to_copy) {
						throw new NBError.TRUNCATED_PAGE ("Truncated page");
					}
					size = temp_stream.write (buffer);
					if (size != to_copy) {
						throw new NBError.MEDIA_COPY ("Media copy error");
					}
					copied += to_copy;
				}
				var widget = new Video.for_file (temp);
				page.add_media (widget, width);
				break;
			default:
				throw new NBError.BAD_ENTRY ("Invalid entry type in page");
			}
		}
	}

	public ArrayList<string> page_names () {
		return pages;
	}

	public void do_rename (string old_name, string new_name) {
		var index = pages.index_of (old_name);
		return_if_fail (index != -1);
		pages.set (index, new_name);
		to_rename.set (old_name, new_name);
	}

	public void do_delete (string name) {
		pages.remove (name);
		to_delete.add (name);
	}

	public void do_insert (string name) {
		pages.add (name);
		to_delete.remove (name);
	}

	public void sync () throws Error {
		foreach (string name in to_delete) {
			var path = page_path (name);
			var file = dir.get_child (path);
			try {
				file.delete ();
			} catch (Error e) {}
		}
		foreach (Map.Entry<string, string> entry in to_rename) {
			var old_path = page_path (entry.key);
			var new_path = page_path (entry.value);
			var file = dir.get_child (old_path);
			if (file.query_exists ()) {
				file.set_display_name (new_path);
			}
		}
	}
}

public class GN.NotebookWriter {
	public NotebookWriter (File dir) {
		this.dir = dir;
	}

	private File dir;

	public void write_toc (ArrayList<string> page_names) throws Error {
		if (!dir.query_exists ()) {
			dir.make_directory ();
		}
		var toc_file = dir.get_child (TOC_FILE);
		try {
			toc_file.delete ();
		} catch (Error e) {}
		var toc = new DataOutputStream (
			toc_file.create (FileCreateFlags.REPLACE_DESTINATION));
		toc.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);
		var header = TOCHeader ();
		header.magic = MAGIC;
		header.version = VERSION;
		header.page_count = page_names.size;
		header.reserved = 0;
		header.modify_time = get_real_time () / 1000000;
		toc.write ((uint8[]) header);
		foreach (string name in page_names) {
			name += "\n";
			toc.write (name.data);
		}
	}

	public void write_page (string name, Page page) throws Error {
		var path = page_path (name);
		DataOutputStream stream;
		var file = dir.get_child (path);
		try {
			file.delete ();
		} catch (Error e) {}
		stream = new DataOutputStream (
			file.create (FileCreateFlags.REPLACE_DESTINATION));
		stream.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);
		var header = PageHeader ();
		header.magic = MAGIC;
		header.entry_count = 0;
		for (var child = page.get_first_child (); child != null;
			 child = child.get_next_sibling ()) {
			header.entry_count++;
		}
		header.modify_time = get_real_time () / 1000000;
		stream.write ((uint8[]) header);

		for (var child = page.get_first_child (); child != null;
			 child = child.get_next_sibling ()) {
			var eh = EntryHeader ();
			if (child is TextView) {
				var widget = child as TextView;
				eh.type = EntryType.TEXT;
				eh.flags = 0;
				eh.length = widget.buffer.text.length;
				eh.size = ((eh.length - 1) | 7) + 1;
				stream.write ((uint8[]) eh);
				stream.put_string (widget.buffer.text);
				for (var i = 0; i < eh.size - eh.length; i++) {
					stream.put_byte ('\0');
				}
			} else if (child is ImageEntry) {
				var widget = child as ImageEntry;
				eh.type = EntryType.IMAGE;
				eh.flags = widget.flags;
				eh.length = widget.images;
				eh.size = 0;
				for (var c = widget.get_first_child (); c != null;
					 c = c.get_next_sibling ()) {
					var image = c as Picture;
					var texture = image.get_paintable () as Texture;
					var bytes =
						texture.save_to_tiff_bytes ().get_data ().length;
					bytes = ((bytes - 1) | 7) + 1;
					eh.size += sizeof (MediaHeader) + bytes;
				}
				stream.write ((uint8[]) eh);

				for (var c = widget.get_first_child (); c != null;
					 c = c.get_next_sibling ()) {
					var image = c as Picture;
					var texture = image.get_paintable () as Texture;
					var mh = MediaHeader ();
					mh.width = (uint16) texture.width;
					mh.height = (uint16) texture.height;
					mh.reserved = 0;
					var bytes = texture.save_to_tiff_bytes ().get_data ();
					mh.size = bytes.length;
					mh.offset = ((mh.size - 1) | 7) + 1;
					stream.write ((uint8[]) mh);
					stream.write (bytes);
					for (var i = 0; i < mh.offset - mh.size; i++) {
						stream.put_byte ('\0');
					}
				}
			} else if (child is Video) {
				var widget = child as Video;
				var video = widget.get_file ();
				eh.type = EntryType.MEDIA;
				eh.flags = 0;
				eh.length = 0;
				eh.size = video.query_info ("standard::size", 0).get_size ();
				stream.write ((uint8[]) eh);
				var input = new DataInputStream (video.read ());
				stream.splice (input, 0);
			} else {
				throw new NBError.BAD_WIDGET ("Found invalid widget in page");
			}
		}
	}
}
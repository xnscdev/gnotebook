using Gtk;

public abstract class GN.UndoItem {
	public abstract void do_undo (Page page);
	public abstract void do_redo (Page page);
}

public class GN.TextInsert : UndoItem {
	public TextInsert (TextIter iter, string text) {
	    base ();
		buffer = iter.get_buffer ();
		offset = iter.get_offset ();
		this.text = text;
	}

	private unowned TextBuffer buffer;
	private string text;
	private int offset;

	public override void do_undo (Page page) {
		TextIter start;
		TextIter end;
		buffer.get_iter_at_offset (out start, offset);
		buffer.get_iter_at_offset (out end, offset + text.length);
		page.mask_delete ();
		buffer.delete (ref start, ref end);
		page.unmask_delete ();
	}

	public override void do_redo (Page page) {
		TextIter iter;
		buffer.get_iter_at_offset (out iter, offset);
		page.mask_insert ();
		buffer.insert (ref iter, text, -1);
		page.unmask_insert ();
	}
}

public class GN.TextDelete : UndoItem {
	public TextDelete (TextIter start, TextIter end) {
		base ();
		buffer = start.get_buffer ();
		offset = start.get_offset ();
		text = buffer.get_slice (start, end, true);
	}

	private unowned TextBuffer buffer;
	private string text;
	private int offset;

	public override void do_undo (Page page) {
		TextIter iter;
		buffer.get_iter_at_offset (out iter, offset);
		page.mask_insert ();
		buffer.insert (ref iter, text, -1);
		page.unmask_insert ();
	}

	public override void do_redo (Page page) {
		TextIter start;
		TextIter end;
		buffer.get_iter_at_offset (out start, offset);
		buffer.get_iter_at_offset (out end, offset + text.length);
		page.mask_delete ();
		buffer.delete (ref start, ref end);
		page.unmask_delete ();
	}
}

public class GN.CreateEntry : UndoItem {
	public CreateEntry (Widget widget) {
		base ();
		this.widget = widget;
		sibling = widget.get_prev_sibling ();
	}

	private Widget widget;
	private Widget? sibling;

	public override void do_undo (Page page) {
		page.remove (widget);
	}

	public override void do_redo (Page page) {
		if (sibling == null) {
			page.prepend (widget);
		} else {
			page.insert_child_after (widget, sibling);
		}
	}
}
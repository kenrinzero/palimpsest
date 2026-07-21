meta:
  id: wsvqa
  title: Westwood Studios VQA video file header
  endian: le
doc: |
  Westwood Studios VQA video file header (IFF-style container).

  The file uses an IFF/RIFF-like structure: a "FORM" chunk (big-endian
  size) containing a "WVQA" form, which in turn holds a "VQHD" header
  chunk with dimensions, frame rate, and audio parameters.

  Proven against ffprobe 6.1.1-3ubuntu5 on a FATE-suite sample
  (`small-cut-v3.vqa`, 140×110 @ 15 fps, ws_vqa + adpcm_ima_ws
  22050 Hz/1 ch).  Gallery status: **net-new** — no VQA entry at
  formats.kaitai.io.  Independence regime: **third-party**.

seq:
  - id: form_tag
    contents: 'FORM'
    doc: IFF container tag.
  - id: form_size
    type: u4be
    doc: Size of everything after this field (big-endian IFF convention).
  - id: form_type
    contents: 'WVQA'
    doc: IFF form type identifier.
  - id: vqhd_tag
    contents: 'VQHD'
    doc: VQA header chunk tag.
  - id: vqhd_size
    type: u4be
    valid: 42
    doc: Fixed 42-byte size of the VQHD data after this field.
  - id: version
    type: u2
    doc: VQA format version (1, 2, or 3).
  - id: vqa_flags
    type: u2
    doc: Flags (bit 0 = has sound, etc.).
  - id: num_frames
    type: u2
    doc: Number of frames.
  - id: width
    type: u2
    doc: Frame width in pixels.
  - id: height
    type: u2
    doc: Frame height in pixels.
  - id: block_w
    type: u1
    doc: Macroblock width (typically 4).
  - id: block_h
    type: u1
    doc: Macroblock height (typically 2).
  - id: frame_rate
    type: u1
    doc: Frame rate in fps.
  - id: group_size
    type: u1
    doc: Frame grouping size, measured in frames per codebook.
  - id: num_1_colors
    type: u2
    doc: Number of one-color entries.
  - id: codebook_entries
    type: u2
    doc: Number of codebook entries.
  - id: x_pos
    type: u2
    doc: Horizontal playback position (0xFFFF requests centering).
  - id: y_pos
    type: u2
    doc: Vertical playback position (0xFFFF requests centering).
  - id: max_frame_size
    type: u2
    doc: Size of the largest frame.
  - id: sample_rate
    type: u2
    doc: Primary audio sample rate in Hz.
  - id: channels
    type: u1
    doc: Number of primary audio channels.
  - id: bits_per_sample
    type: u1
    doc: Primary audio sample size in bits.
  - id: alt_sample_rate
    type: u2
    doc: Alternate audio stream sample rate in Hz.
  - id: alt_channels
    type: u1
    doc: Number of alternate audio channels.
  - id: alt_bits_per_sample
    type: u1
    doc: Alternate audio sample size in bits.
  - id: future_use
    type: u2
    repeat: expr
    repeat-expr: 5
    doc: Five reserved words completing the fixed 42-byte VQHD payload.

instances:
  codec_label:
    value: '"ws_vqa"'
    doc: |
      ffprobe codec name — VQA containers always carry the Westwood
      VQA video codec.  Constant for this format.

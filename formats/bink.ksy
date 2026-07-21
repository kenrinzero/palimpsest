meta:
  id: bink
  title: Bink (BIK) base video header
  endian: le
doc: |
  RAD Game Tools Bink base video header (supported BIK revisions b, f, g,
  h, i, and k).

  The 44-byte base header carries dimensions, frame count, frame rate,
  video flags, and the audio-track count.  Per-track audio records and
  frame offsets follow and are intentionally deferred to a depth unit.

  Proven against ffprobe 6.1.1-3ubuntu5 on a FATE-suite BIKi sample
  (`RazOnBull.bik`, 640×480 @ 30 fps, binkvideo + binkaudio_dct
  44100 Hz/2 ch).  Gallery status: **net-new** — no Bink entry at
  formats.kaitai.io.  Independence regime: **third-party**.

seq:
  - id: signature_prefix
    contents: 'BIK'
    doc: Bink signature prefix.
  - id: version
    type: u1
    valid:
      any-of: [0x62, 0x66, 0x67, 0x68, 0x69, 0x6b]
    doc: Supported BIK revision letter (b, f, g, h, i, or k).
  - id: file_size_minus_8
    type: u4
    doc: Stored total file size minus the first 8 bytes.
  - id: num_frames
    type: u4
    doc: Total frame count.
  - id: largest_frame_size
    type: u4
    doc: Size in bytes of the largest single frame.
  - id: frame_count_word_2
    type: u4
    doc: Second frame-count word; equals num_frames in the proven BIKi fixture.
  - id: width
    type: u4
    doc: Frame width in pixels.
  - id: height
    type: u4
    doc: Frame height in pixels.
  - id: fps_num
    type: u4
    doc: Frame rate numerator.
  - id: fps_den
    type: u4
    doc: Frame rate denominator (typically 1 for integer rates).
  - id: video_flags
    type: u4
    doc: Video stream flags; interpretation varies by Bink revision.
  - id: num_audio_tracks
    type: u4
    doc: Number of per-track audio records following the base header.

instances:
  file_size:
    value: file_size_minus_8 + 8
    doc: Total file size in bytes.

  codec_label:
    value: '"binkvideo"'
    doc: |
      ffprobe codec name — Bink containers always carry the Bink
      video codec.  Constant for this format.

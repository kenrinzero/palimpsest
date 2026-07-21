meta:
  id: smk
  title: Smacker (SMK) fixed video header
  endian: le
doc: |
  RAD Game Tools Smacker video file header (SMK2/SMK4).

  The 104-byte fixed header carries dimensions, stored frame count, frame
  timing, and flags.  The remainder contains audio-size entries and tree,
  table, and audio descriptors; this header unit consumes that region but
  leaves its internal layout opaque for a later depth unit.

  Proven against ffprobe 6.1.1-3ubuntu5 on a FATE-suite SMK2 sample
  (`wetlogo.smk`, 320×200, 100 frames, smackvideo + smackaudio 22050 Hz/1 ch).
  Gallery status: **net-new** — no Smacker entry at formats.kaitai.io.
  Independence regime: **third-party** (FATE-suite bytes).

seq:
  - id: signature_prefix
    contents: 'SMK'
    doc: Smacker signature prefix.
  - id: version
    type: u1
    valid:
      any-of: [0x32, 0x34]
    doc: ASCII "2" or "4", selecting SMK2 or SMK4.
  - id: width
    type: u4
    doc: Frame width in pixels.
  - id: height
    type: u4
    doc: Frame height in pixels.
  - id: stored_frames
    type: u4
    doc: Stored frame count, excluding an optional ring frame.
  - id: pts_inc
    type: s4
    doc: |
      Signed PTS increment per frame.  Smacker uses a 100,000-unit internal
      time base.  Positive values are multiplied by 100, so wetlogo.smk's
      value 71 yields 1000/71 ≈ 14.08 fps; negative values use their
      absolute value directly.
  - id: flags
    type: u4
    doc: |
      Flags: bit 0 = ring frame present, bit 1 = Y-interlaced,
      bit 2 = Y-doubled.
  - id: header_remainder
    size: 80
    doc: |
      Remaining bytes of the fixed 104-byte header.  Audio-size entries,
      tree/table sizes, audio descriptors, and padding are intentionally
      deferred until a depth unit validates their semantics.

instances:
  total_frames:
    value: stored_frames + (flags & 1)
    doc: Stored frames plus the optional ring frame indicated by flags bit 0.

  frame_duration_units:
    value: 'pts_inc > 0 ? pts_inc * 100 : 0 - pts_inc'
    doc: Frame duration numerator on Smacker's 100,000-unit time base.

  codec_label:
    value: '"smackvideo"'
    doc: |
      ffprobe codec name — Smacker containers always carry the Smacker
      video codec.  The codec name is constant for this format.

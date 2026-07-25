meta:
  id: flic
  title: Autodesk Animator FLI/FLC header and frame chunks
  endian: le
doc: |
  Autodesk Animator FLI/FLC animation — depth unit.

  * 128-byte fixed header: dimensions, declared frame count, FLI/FLC
    magic (0xAF11 / 0xAF12), and timing (FLC = milliseconds, FLI =
    1/70 s ticks)
  * Animator Pro oframe1 / oframe2 at absolute offsets 0x50 / 0x54
    (byte offsets of the first and second frame records)
  * size-delimited frame records to end of file; each frame has a 16-byte
    preamble (size, magic 0xF1FA/0xF100, subchunk count, reserved) and
    that many subchunks (size includes the 6-byte subchunk header)

  FLC files commonly store a ring/prefix frame, so the number of on-disk
  frame records is often `frames + 1`.  This unit walks with `repeat: eos`
  rather than trusting a fixed count.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE `jj00c2.fli` (FLC
  640×480, speed 72 ms, 26 declared frames, 27 on-disk records).
  Gallery: **net-new**. Independence: **third-party**.

seq:
  - id: size
    type: u4
    doc: Total file size in bytes (self-length).
  - id: magic
    type: u2
    valid:
      any-of: [0xaf11, 0xaf12]
    doc: 0xAF11 = FLI, 0xAF12 = FLC.
  - id: frames
    type: u2
    doc: Declared animation frame count (ring frame not included).
  - id: width
    type: u2
    doc: Frame width in pixels.
  - id: height
    type: u2
    doc: Frame height in pixels.
  - id: depth
    type: u2
    doc: Color depth (8 = 256-color palette).
  - id: flags
    type: u2
    doc: Animator state flags.
  - id: speed_raw
    type: u4
    doc: |
      Timing at offset 0x10.  FLC = milliseconds between frames;
      FLI = delay in 1/70-second ticks.
  - id: header_mid
    size: 60
    doc: |
      Bytes from offset 0x14 through 0x4F — creation stamps, aspect,
      and Animator Pro extended fields before the frame-offset pair.
      Left opaque; oframe1/oframe2 are the depth-critical offsets.
  - id: oframe1
    type: u4
    doc: Absolute file offset of the first frame record (normally 128).
  - id: oframe2
    type: u4
    doc: Absolute file offset of the second frame record.
  - id: header_tail
    size: 40
    doc: Remainder of the fixed 128-byte header after oframe2.
  - id: frame_records
    type: frame
    repeat: eos
    doc: All frame records through end of file (includes optional ring frame).

types:
  frame:
    seq:
      - id: size
        type: u4
        doc: Total frame record size including this preamble.
      - id: magic
        type: u2
        valid:
          any-of: [0xf1fa, 0xf100]
        doc: 0xF1FA = standard frame, 0xF100 = prefix/ring variant.
      - id: chunks_count
        type: u2
        doc: Number of subchunks in this frame.
      - id: reserved
        size: 8
        doc: Reserved frame-header bytes.
      - id: subchunks
        type: subchunk
        repeat: expr
        repeat-expr: chunks_count
        doc: Palette / delta / full-frame subchunks.

  subchunk:
    seq:
      - id: size
        type: u4
        doc: Subchunk size including this 6-byte header.
      - id: chunk_type
        type: u2
        doc: |
          Common types: 4 = COLOR_256, 7 = DELTA_FLC (SS2),
          15 = BYTE_RUN (full compressed frame), 11 = COLOR_64,
          12 = DELTA_FLI, 13 = BLACK, 16 = LITERAL.
      - id: data
        size: size - 6
        doc: Subchunk payload (compressed pixels / palette ops).

instances:
  frame_delay_msec:
    value: speed_raw
    if: magic == 0xaf12
    doc: FLC frame delay in milliseconds; absent for tick-based FLI files.

  walked_frame_count:
    value: frame_records.size
    doc: On-disk frame records walked (declared frames plus optional ring).

  codec_label:
    value: '"flic"'
    doc: |
      ffprobe codec name — FLI/FLC containers always carry the "flic"
      video codec.  There is only one codec for this format.

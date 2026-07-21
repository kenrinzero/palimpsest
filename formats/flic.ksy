meta:
  id: flic
  title: Autodesk Animator FLI/FLC animation header
  endian: le
doc: |
  Autodesk Animator FLI/FLC animation file header.

  The 128-byte header carries dimensions, frame count, a raw timing value,
  and a magic number distinguishing FLI (0xAF11) from FLC (0xAF12).  FLC
  stores timing in milliseconds; FLI stores 1/70-second ticks.

  Proven against ffprobe 6.1.1-3ubuntu5 on a FATE-suite FLC sample
  (`jj00c2.fli`, 640×480 @ 125/9 fps, 26 frames).  Gallery status:
  **net-new** — no FLI/FLC entry at formats.kaitai.io.
  Independence regime: **third-party** (FATE-suite bytes, full independence).

seq:
  - id: size
    type: u4
    doc: Total file size in bytes.
  - id: magic
    type: u2
    valid:
      any-of: [0xaf11, 0xaf12]
    doc: 0xAF11 = FLI, 0xAF12 = FLC.
  - id: frames
    type: u2
    doc: Number of frames.
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
    doc: Animator state flags; detailed semantics are deferred to a depth unit.
  - id: speed_raw
    type: u4
    doc: |
      32-bit timing value at offset 0x10.  For FLC files this is the
      delay between frames in milliseconds; for FLI files it is measured
      in 1/70-second ticks.
  - id: header_remainder
    size: 108
    doc: |
      Remaining bytes of the fixed 128-byte FLIC header.  Their extended
      layout is intentionally left opaque until a depth unit validates it.

instances:
  frame_delay_msec:
    value: speed_raw
    if: magic == 0xaf12
    doc: FLC frame delay in milliseconds; absent for tick-based FLI files.

  codec_label:
    value: '"flic"'
    doc: |
      ffprobe codec name — FLI/FLC containers always carry the "flic"
      video codec.  There is only one codec for this format.

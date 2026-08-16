meta:
  id: dxa
  title: Feeble Files / ScummVM DXA header
  endian: be
doc: |
  ScummVM / Feeble Files DXA container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/dxa.c):

  * "DEXA" magic
  * u8 flags, u16be frame count, s32be fps, u16be
    width, u16be stored height
  * flags 0x40 / 0x80 mean interlaced or double-height;
    reported height is stored height >> 1
  * optional WAVE chunk after the header (absent on this
    FATE head — video only)
  * FRAM / NULL / CMAP payload (uninterpreted)

  FPS encoding: fps > 0 → 1000/fps; fps < 0 →
  100000/(-fps); fps == 0 → 10/1.  This sample is
  -8333 → 100000/8333.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `dxa/scummvm.dxa` (640×200 dxa, 637 frames, video
  only).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: magic
    contents: DEXA
    doc: DXA signature.
  - id: flags
    type: u1
    doc: |
      0x80 = interlaced, 0x40 = double height.  Either
      bit halves the reported height.
  - id: frames
    type: u2
    valid:
      min: 1
    doc: Declared frame count (ffprobe video duration_ts).
  - id: fps_raw
    type: s4
    doc: Signed FPS encoding.  Negative uses a 100000 numerator.
  - id: raw_width
    type: u2
    valid:
      min: 1
      max: 2048
    doc: Frame width in pixels.
  - id: raw_height
    type: u2
    valid:
      min: 1
      max: 2048
    doc: Stored height.  May be twice the reported height.
  - id: rest
    size-eos: true
    doc: Optional WAVE plus FRAM/NULL/CMAP frames (uninterpreted).

instances:
  width:
    value: raw_width
    doc: Frame width in pixels.
  height:
    value: '(flags & 0xc0) != 0 ? raw_height >> 1 : raw_height'
    doc: Reported height after the interlaced / double-height flag.
  fps_num:
    value: 'fps_raw > 0 ? 1000 : (fps_raw < 0 ? 100000 : 10)'
    doc: r_frame_rate numerator after the demuxer swap.
  fps_den:
    value: 'fps_raw > 0 ? fps_raw : (fps_raw < 0 ? -fps_raw : 1)'
    doc: r_frame_rate denominator (absolute fps_raw, or 1 if zero).
  codec_label:
    value: '"dxa"'
    doc: ffprobe video codec_name.  DXA video has no fourcc.

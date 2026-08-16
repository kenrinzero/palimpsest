meta:
  id: siff
  title: Beam Software SIFF header
  endian: le
doc: |
  Beam Software SIFF / VBV1 container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/siff.c):

  * SIFF + u32be size + VBV1
  * VBHD + u32be 32 + u16le version 1, width, height
  * skip 4, u16le frames, bits, sample rate, 16 zero bytes
  * BODY + u32be size, then packets (uninterpreted)
  * Video is always VB, 12 fps (demuxer constant)
  * Audio is PCM u8 mono when rate != 0

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `SIFF/INTRO_B.VB` (320×240 vb @ 12 fps + pcm_u8
  22050 Hz/1 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: magic
    contents: SIFF
    doc: SIFF container signature.
  - id: form_size
    type: u4be
    doc: Size of everything after this field (big-endian).
  - id: form_type
    contents: VBV1
    doc: VBV1 video form.  SOUN is the audio-only sibling.
  - id: vbhd_tag
    contents: VBHD
    doc: Video header chunk tag.
  - id: vbhd_size
    type: u4be
    valid:
      eq: 32
    doc: VBHD payload size.  Must be 32.
  - id: version
    type: u2
    valid:
      eq: 1
    doc: Header version.
  - id: width
    type: u2
    valid:
      min: 1
    doc: Frame width in pixels.
  - id: height
    type: u2
    valid:
      min: 1
    doc: Frame height in pixels.
  - id: unused
    size: 4
    doc: Unused word skipped by the demuxer.
  - id: frames
    type: u2
    valid:
      min: 1
    doc: Declared frame count (ffprobe video duration_ts).
  - id: bits
    type: u2
    doc: Audio bits per sample (8 on this FATE head).
  - id: sample_rate
    type: u2
    valid:
      min: 1
    doc: Audio sample rate in Hz.  Non-zero creates the audio stream.
  - id: vbhd_pad
    size: 16
    doc: Reserved zeros at the end of VBHD.
  - id: body_tag
    contents: BODY
    doc: Packet-stream chunk tag.
  - id: body_size
    type: u4be
    doc: BODY size.  May exceed the on-disk tail on truncated files.
  - id: rest
    size-eos: true
    doc: Interleaved video/audio packets (uninterpreted).

instances:
  fps:
    value: 12
    doc: SIFF frame rate.  Demuxer constant (time base 1/12).
  audio_channels:
    value: 1
    doc: SIFF audio is always mono.  Format constant.
  audio_bit_rate:
    value: sample_rate * 8 * 1
    doc: ffprobe audio bit_rate (rate × 8-bit × mono).
  codec_label:
    value: '"vb"'
    doc: ffprobe video codec_name.  Fourcc is VBV1.
  audio_codec_label:
    value: '"pcm_u8"'
    doc: ffprobe audio codec_name.  SIFF audio is PCM u8.

meta:
  id: yop
  title: Psygnosis YOP header
  endian: le
doc: |
  Psygnosis YOP container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/yop.c):

  * "YO" signature
  * 4 unused bytes, then u8 frame rate, u8 frame-size
    units (×2048), u16le width, u16le height
  * 8-byte video extradata (palette count, audio block
    length at +6)
  * Frame payload starts at offset 2048 (uninterpreted)

  Audio is always ADPCM IMA APC, 22050 Hz mono — those
  numbers are format constants.  FFmpeg emits audio as
  stream 0 and video as stream 1.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `yop/test1.yop` (580×174 yop @ 12 fps + adpcm_ima_apc
  22050 Hz/1 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: magic
    contents: YO
    doc: YOP signature.
  - id: unused
    size: 4
    doc: Unused header prefix (skipped by the demuxer).
  - id: frame_rate
    type: u1
    valid:
      min: 1
    doc: Frames per second.
  - id: frame_size_units
    type: u1
    valid:
      min: 1
    doc: Frame size in 2048-byte units.
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
  - id: extradata
    size: 8
    doc: Video extradata passed through to the decoder.
  - id: header_pad
    size: 2048 - 20
    doc: Remainder of the 2048-byte header block.
  - id: packets
    size-eos: true
    doc: Interleaved audio/video frames (uninterpreted).

instances:
  frame_size:
    value: frame_size_units * 2048
    doc: Declared per-frame size in bytes.
  palette_size:
    value: extradata[0] * 3 + 4
    doc: Palette bytes from extradata[0].
  audio_block_length:
    value: extradata[6] + extradata[7] * 256
    doc: Audio block length, little-endian u16 at extradata+6.
  audio_sample_rate:
    value: 22050
    doc: YOP audio rate.  Format constant, not a file field.
  audio_channels:
    value: 1
    doc: YOP audio is always mono.  Format constant.
  audio_bit_rate:
    value: 22050 * 4 * 1
    doc: ffprobe audio bit_rate (4-bit ADPCM × mono).
  codec_label:
    value: '"yop"'
    doc: ffprobe video codec_name.  YOP video has no fourcc.
  audio_codec_label:
    value: '"adpcm_ima_apc"'
    doc: ffprobe audio codec_name.  YOP audio is always IMA APC.

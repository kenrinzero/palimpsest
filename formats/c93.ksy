meta:
  id: c93
  title: Interplay C93 header
  endian: le
doc: |
  Interplay C93 (Cyberia) container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/c93.c):

  * 512 block records (u16le sector index, u8 length,
    u8 frames).  First nonempty record starts at sector 1.
  * First block: 32 u32le frame offsets, then the first
    video frame, optional 768-byte palette, then a VOC
    audio packet (26-byte header + type-1 block).
  * Video is always 320×192 C93; frame rate is 25/2.
    Those numbers are format constants.
  * Audio sample rate comes from the VOC type-1 time
    constant (1000000 / (256 - tc)).

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `cyberia-c93/intro1.c93` (320×192 c93 @ 25/2 + pcm_u8
  16129 Hz/1 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: block_records
    type: block_record
    repeat: expr
    repeat-expr: 512
    doc: Fixed 512-entry block table (2048 bytes).
  - id: first_block
    type: first_block
    doc: Block at sector 1 (immediately after the table).
  - id: rest
    size-eos: true
    doc: Remaining blocks (uninterpreted).

types:
  block_record:
    seq:
      - id: index
        type: u2
        doc: Starting CD sector of this block (×2048).
      - id: length
        type: u1
        doc: Block length in sectors.
      - id: frames
        type: u1
        valid:
          max: 32
        doc: Frame count in this block (0 if unused).
  first_block:
    seq:
      - id: frame_offsets
        type: u4
        repeat: expr
        repeat-expr: 32
        doc: Offsets of up to 32 frames from the block start.
      - id: skip_to_frame
        size: frame_offsets[0] - 128
        doc: Gap between the offset table (128 bytes) and frame 0.
      - id: len_video
        type: u2
        doc: First video-frame payload size.
      - id: video
        size: len_video
        doc: First video frame (uninterpreted).
      - id: len_palette
        type: u2
        doc: Palette size (768 if present, else 0).
      - id: palette
        size: len_palette
        doc: Optional 768-byte palette.
      - id: audio_size
        type: u2
        doc: Following VOC packet size.
      - id: voc
        type: voc_packet
        if: audio_size > 42
        doc: VOC header plus first type-1 sound block.
  voc_packet:
    seq:
      - id: magic
        contents: 'Creative Voice File'
        doc: VOC signature.
      - id: eof_byte
        contents: [0x1a]
        doc: DOS EOF marker.
      - id: data_offset
        type: u2
        valid:
          min: 26
        doc: Offset of the first VOC data block.
      - id: version
        type: u2
        doc: VOC version word.
      - id: id_code
        type: u2
        doc: Complementary version check word.
      - id: header_pad
        size: data_offset - 26
        doc: Padding to data_offset (empty when offset is 26).
      - id: block_type
        type: u1
        valid:
          eq: 1
        doc: VOC block type.  1 = legacy sound data.
      - id: size_b0
        type: u1
      - id: size_b1
        type: u1
      - id: size_b2
        type: u1
      - id: time_constant
        type: u1
        doc: VOC type-1 time constant.
      - id: packing
        type: u1
        doc: VOC type-1 packing byte (0 = 8-bit PCM).

instances:
  width:
    value: 320
    doc: C93_WIDTH.  Format constant, not a file field.
  height:
    value: 192
    doc: C93_HEIGHT.  Format constant, not a file field.
  fps_num:
    value: 25
    doc: C93 frame-rate numerator.  Demuxer constant (2/25 time base).
  fps_den:
    value: 2
    doc: C93 frame-rate denominator.  Demuxer constant.
  audio_sample_rate:
    value: 1000000 / (256 - first_block.voc.time_constant)
    doc: VOC type-1 rate (1000000 / (256 - time_constant)).
  audio_channels:
    value: 1
    doc: C93 VOC type-1 audio is mono.
  audio_bit_rate:
    value: audio_sample_rate * 8 * 1
    doc: ffprobe audio bit_rate (rate × 8-bit × mono).
  codec_label:
    value: '"c93"'
    doc: ffprobe video codec_name.  C93 video has no fourcc.
  audio_codec_label:
    value: '"pcm_u8"'
    doc: ffprobe audio codec_name from the VOC type-1 packing.

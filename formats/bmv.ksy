meta:
  id: bmv
  title: Discworld II BMV header
  endian: le
doc: |
  Discworld II BMV container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/bmv.c):

  * No file header and no magic.  Probe is by extension.
  * Packet stream: u8 type, u24le size, then size bytes.
    Type 0 is NOP (size omitted); type 1 is END.
    0x20 marks an audio packet.
  * Video is always 640×429 @ 12 fps bmv_video.
  * Audio is always BMV ADPCM, 22050 Hz stereo.
    Those numbers are format constants, not file fields.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `bmv/SURFING-partial.BMV` (640×429 bmv_video @ 12 fps +
  bmv_audio 22050 Hz/2 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: first_type
    type: u1
    valid:
      min: 2
    doc: First packet type.  0 = NOP, 1 = END; this head starts with data.
  - id: first_size_lo
    type: u2
    doc: Low 16 bits of the first packet payload size.
  - id: first_size_hi
    type: u1
    doc: High 8 bits of the first packet payload size.
  - id: first_payload
    size: len_first_payload
    doc: First packet body (uninterpreted).
  - id: rest
    size-eos: true
    doc: Remaining type/size packets (uninterpreted).

instances:
  len_first_payload:
    value: first_size_lo + first_size_hi * 65536
    doc: First packet payload size (24-bit little-endian).
  width:
    value: 640
    doc: BMV_WIDTH.  Format constant, not a file field.
  height:
    value: 429
    doc: BMV_HEIGHT.  Format constant, not a file field.
  fps:
    value: 12
    doc: BMV frame rate.  Demuxer constant (time base 1/12).
  audio_sample_rate:
    value: 22050
    doc: BMV audio rate.  Format constant, not a file field.
  audio_channels:
    value: 2
    doc: BMV audio is always stereo.  Format constant.
  codec_label:
    value: '"bmv_video"'
    doc: ffprobe video codec_name.  BMV video has no fourcc.
  audio_codec_label:
    value: '"bmv_audio"'
    doc: ffprobe audio codec_name.  BMV audio has no fourcc.

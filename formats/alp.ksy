meta:
  id: alp
  title: LEGO Racers ALP header
  endian: le
doc: |
  LEGO Racers ALP audio container (.tun music / .pcm sfx) — header unit.

  Layout (FFmpeg 6.1.1 libavformat/alp.c):

  * magic "ALP "
  * header_size after that word: 8 (.tun) or 12 (.pcm)
  * six-byte "ADPCM\\0", unk byte, channel count
  * u4 sample rate only when header_size is 12
  * raw ADPCM IMA ALP payload (uninterpreted)

  .tun files have no rate field and always play at 22050 Hz.
  This fixture is a .tun (header_size 8) from the alp muxer's
  extension autodetection.

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 22050 Hz
  mono sample.  Gallery: **net-new**. Independence: **self-generated**.

seq:
  - id: magic
    contents: 'ALP '
    doc: Signature ALP followed by a space.
  - id: header_size
    type: u4
    valid:
      any-of: [8, 12]
    doc: Bytes after this field.  8 = .tun (implied 22050 Hz), 12 = .pcm.
  - id: adpcm_tag
    contents: [0x41, 0x44, 0x50, 0x43, 0x4d, 0x00]
    doc: Literal "ADPCM" plus a trailing NUL.
  - id: unk1
    type: u1
    doc: Unknown; muxer writes 0.
  - id: num_channels
    type: u1
    valid:
      min: 1
      max: 2
    doc: Channel count (1 or 2).
  - id: stored_rate
    type: u4
    if: header_size == 12
    valid:
      min: 1
      max: 44100
    doc: Explicit sample rate on .pcm files only.
  - id: payload
    size-eos: true
    doc: Uninterpreted ADPCM IMA ALP bytes.

instances:
  sample_rate:
    value: 'header_size == 12 ? stored_rate : 22050'
    doc: Effective rate.  .tun files have no field and are always 22050.
  channels:
    value: num_channels
    doc: Channel count from the header.
  duration_samples:
    value: '((_io.size - 8 - header_size) * 2) / num_channels'
    doc: |
      IMA nibble duration used by the demuxer (2 samples per byte,
      divided by channel count).
  codec_label:
    value: '"adpcm_ima_alp"'
    doc: ffprobe codec_name.  ALP always carries IMA ALP ADPCM.

meta:
  id: bethsoftvid
  title: Bethesda Softworks VID header
  endian: le
doc: |
  Bethesda Softworks VID container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/bethsoftvid.c):

  * "VID\\0", u8 version 2
  * u16le: nframes, width, height, global delay, unused 14
  * Block stream.  This FATE head starts with a 0x02
    palette (768 bytes) then a 0x7C first-audio block.
  * First-audio: unused u16, u8 time constant, u16le
    length, PCM u8 payload.
  * Sample rate is 1000000 / (256 - time_constant).
    Audio is always mono PCM u8 (stream 0; video is 1).
  * 14 fps is a demuxer-reported rate, not read from
    the unused 14 word.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `bethsoft-vid/ANIM0001.VID` (320×200 bethsoftvid +
  pcm_u8 11111 Hz/1 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: magic
    contents: [0x56, 0x49, 0x44, 0x00]
    doc: Literal "VID" plus NUL.
  - id: version
    type: u1
    valid:
      eq: 2
    doc: Header version.  Probe requires 2.
  - id: nframes
    type: u2
    valid:
      min: 1
    doc: Declared frame count.
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
  - id: global_delay
    type: u2
    doc: Added to each frame's own delay.
  - id: unused_14
    type: u2
    doc: Always 14 on known files.  The demuxer skips it.
  - id: preamble
    type: block
    repeat: until
    repeat-until: _.is_first_audio
    doc: Palette blocks through the first-audio block.
  - id: rest
    size-eos: true
    doc: Remaining audio/video/EOF blocks (uninterpreted).

types:
  block:
    seq:
      - id: block_type
        type: u1
        doc: 0x02 palette, 0x7C first-audio, others later.
      - id: palette
        size: 768
        if: block_type == 2
        doc: 256×RGB palette.
      - id: first_audio
        type: first_audio
        if: block_type == 0x7c
        doc: DAC time-constant plus first PCM block.
    instances:
      is_first_audio:
        value: block_type == 0x7c
        doc: Stop the preamble walk on the first-audio block.
  first_audio:
    seq:
      - id: unused
        type: u2
        doc: Unused word before the time constant.
      - id: time_constant
        type: u1
        doc: Sound Blaster DAC time constant.
      - id: len_audio
        type: u2
        doc: PCM u8 payload length.
      - id: audio
        size: len_audio
        doc: First audio payload (uninterpreted).

instances:
  audio_sample_rate:
    value: 1000000 / (256 - preamble.last.first_audio.time_constant)
    doc: 1000000 / (256 - time_constant).
  audio_channels:
    value: 1
    doc: Bethesda VID audio is always mono.  Format constant.
  audio_bit_rate:
    value: audio_sample_rate * 8 * 1
    doc: ffprobe audio bit_rate (rate × 8-bit × mono).
  codec_label:
    value: '"bethsoftvid"'
    doc: ffprobe video codec_name.  VID video has no fourcc.
  audio_codec_label:
    value: '"pcm_u8"'
    doc: ffprobe audio codec_name.  VID audio is PCM u8.

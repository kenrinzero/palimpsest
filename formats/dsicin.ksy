meta:
  id: dsicin
  title: Delphine Software CIN header
  endian: le
doc: |
  Delphine Software International CIN container — header unit.

  Not id Software CIN (`idcin`).  Same `.CIN` extension,
  different container.

  Layout (FFmpeg 6.1.1 libavformat/dsicin.c):

  * u32le marker 0x55AA0000
  * u32le video frame size, u16le width, u16le height
  * u32le audio frequency (must be 22050), u8 bits (16),
    u8 stereo (0), u16le audio frame size
  * Frame packets follow (uninterpreted)
  * 12 fps is a demuxer constant.  Audio is always
    dsicinaudio mono; bit_rate uses 8-bit × rate even
    though the header bits field is 16.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `delphine-cin/LOGO-partial.CIN` (320×160 dsicinvideo
  @ 12 fps + dsicinaudio 22050 Hz/1 ch).  Gallery:
  **net-new**.  Independence: **third-party**.

seq:
  - id: marker
    type: u4
    valid:
      eq: 0x55aa0000
    doc: File marker.  Little-endian 0x55AA0000.
  - id: video_frame_size
    type: u4
    doc: Declared video frame size (unused by the header unit).
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
  - id: audio_frequency
    type: u4
    valid:
      eq: 22050
    doc: Audio sample rate.  Demuxer requires 22050.
  - id: audio_bits
    type: u1
    valid:
      eq: 16
    doc: Header bits field.  Demuxer requires 16.
  - id: audio_stereo
    type: u1
    valid:
      eq: 0
    doc: Stereo flag.  Demuxer requires 0 (mono).
  - id: audio_frame_size
    type: u2
    doc: Declared audio frame size.
  - id: rest
    size-eos: true
    doc: Interleaved video/audio frames (uninterpreted).

instances:
  fps:
    value: 12
    doc: CIN frame rate.  Demuxer constant (time base 1/12).
  audio_channels:
    value: 1
    doc: CIN audio is required to be mono.
  audio_bit_rate:
    value: audio_frequency * 8 * 1
    doc: ffprobe audio bit_rate (rate × 8-bit × mono).
  codec_label:
    value: '"dsicinvideo"'
    doc: ffprobe video codec_name.  Delphine CIN video has no fourcc.
  audio_codec_label:
    value: '"dsicinaudio"'
    doc: ffprobe audio codec_name.  Delphine CIN audio has no fourcc.

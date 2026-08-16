meta:
  id: idcin
  title: id Quake II CIN header
  endian: le
doc: |
  id Software Quake II cinematic (CIN) container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/idcin.c):

  * 20-byte header: width, height, sample rate, bytes/sample,
    channels (all u32le).  No magic; the demuxer probes by
    range checks on these five words.
  * 65536-byte Huffman table (extradata; uninterpreted)
  * interleaved video/audio chunks (uninterpreted)

  Video is always idcin.  Audio is PCM u8 or s16le from
  bytes/sample.  Frame rate 14 fps is a demuxer constant.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `idcin/idlog-2MB.cin` (320×240 idcin + pcm_s16le
  22050 Hz/2 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: width
    type: u4
    valid:
      min: 1
      max: 1024
    doc: Frame width in pixels.
  - id: height
    type: u4
    valid:
      min: 1
      max: 1024
    doc: Frame height in pixels.
  - id: sample_rate
    type: u4
    valid:
      min: 8000
      max: 48000
    doc: Audio sample rate in Hz (0 would mean no audio).
  - id: bytes_per_sample
    type: u4
    valid:
      any-of: [1, 2]
    doc: Audio bytes per sample.  1 = PCM u8, 2 = PCM s16le.
  - id: channels
    type: u4
    valid:
      any-of: [1, 2]
    doc: Audio channel count.
  - id: huffman_table
    size: 65536
    doc: Huffman tables passed through as codec extradata.
  - id: packets
    size-eos: true
    doc: Interleaved video/audio chunks (uninterpreted).

instances:
  audio_bit_rate:
    value: sample_rate * bytes_per_sample * 8 * channels
    doc: ffprobe audio bit_rate (rate × bits × channels).
  codec_label:
    value: '"idcin"'
    doc: ffprobe video codec_name.  CIN video has no fourcc.
  audio_codec_label:
    value: 'bytes_per_sample == 1 ? "pcm_u8" : "pcm_s16le"'
    doc: ffprobe audio codec_name from bytes_per_sample.

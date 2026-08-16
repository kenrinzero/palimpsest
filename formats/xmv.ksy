meta:
  id: xmv
  title: Microsoft Xbox XMV header and audio-track table
  endian: le
doc: |
  Microsoft Xbox Media Video (XMV / .fmv) container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/xmv.c):

  * 16-byte prefix (next/this/max packet sizes + "xobX")
  * version u32le (this unit accepts 2 or 4; others are
    request_sample in FFmpeg)
  * video width, height, duration in milliseconds
  * audio-track count + pad, then 12-byte records
    (WAVE compression tag, channels, rate, bits, flags)
  * packet stream after the header (uninterpreted)

  Video is always WMV2.  This FATE head has one track tagged
  0x0069 (Xbox IMA ADPCM → ffprobe `adpcm_ima_wav`).

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE `xmv/logos1p.fmv`
  (640×480 wmv2, 8500 ms, adpcm_ima_wav 44100 Hz/2 ch).
  Gallery: **net-new**. Independence: **third-party**.

seq:
  - id: next_packet_size
    type: u4
    doc: Size hint for the packet after the current one.
  - id: this_packet_size
    type: u4
    valid:
      min: 36
    doc: Size of the first media packet, including the file header.
  - id: max_packet_size
    type: u4
    doc: Largest packet size in the file.
  - id: magic
    contents: xobX
    doc: XMV signature ("xobX", little-endian "Xbox").
  - id: version
    type: u4
    valid:
      any-of: [2, 4]
    doc: File version.  FFmpeg 6.1.1 request_samples anything else.
  - id: width
    type: u4
    valid:
      min: 1
    doc: Frame width in pixels.
  - id: height
    type: u4
    valid:
      min: 1
    doc: Frame height in pixels.
  - id: duration_ms
    type: u4
    valid:
      min: 1
    doc: Video duration in milliseconds (stream time base 1/1000).
  - id: num_audio_tracks
    type: u2
    valid:
      min: 1
    doc: Number of 12-byte audio-track records that follow.
  - id: reserved
    type: u2
    doc: Unknown padding after the track count.
  - id: audio_tracks
    type: audio_track
    repeat: expr
    repeat-expr: num_audio_tracks
    doc: Per-track WAVE-style format records.

instances:
  audio_sample_rate:
    value: audio_tracks[0].sample_rate
    doc: Sample rate of the first audio track.
  audio_channels:
    value: audio_tracks[0].channels
    doc: Channel count of the first audio track.
  walked_track_count:
    value: audio_tracks.size
    doc: Number of audio-track records actually walked.
  codec_label:
    value: '"wmv2"'
    doc: ffprobe video codec_name.  XMV video is always WMV2.
  audio_codec_label:
    value: >
      audio_tracks[0].compression == 0x69 ? "adpcm_ima_wav" : "unknown"
    doc: ffprobe audio codec_name from the WAVE compression tag.

types:
  audio_track:
    seq:
      - id: compression
        type: u2
        valid:
          eq: 0x69
        doc: WAVE format tag.  0x0069 is Xbox IMA ADPCM.
      - id: channels
        type: u2
        valid:
          min: 1
        doc: Channel count.
      - id: sample_rate
        type: u4
        valid:
          min: 1
        doc: Sample rate in Hz.
      - id: bits_per_sample
        type: u2
        valid:
          min: 1
        doc: Bits per compressed sample (4 for this IMA track).
      - id: flags
        type: u2
        doc: Track flags.  Bits 0–2 mark unsupported ADPCM 5.1 splits.

meta:
  id: vmd
  title: Sierra VMD header
  endian: le
doc: |
  Sierra Video and Music Data (VMD) container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/sierravmd.c):

  * 0x0330-byte header; first u16le is 0x032E (size minus the
    length word itself)
  * width/height at +12/+14; 'iv3' at +24 selects Indeo 3
    (otherwise VMD video)
  * audio at +804: sample rate, block-align (high bit → 16-bit),
    sound-buffer count, flags at +811 (0x80 or 0x02 → stereo)
  * TOC offset at +812 (uninterpreted here)

  Frame rate 10 fps is a demuxer constant, not a file field.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE `vmd/12.vmd`
  (320×240 vmdvideo + vmdaudio 22050 Hz/1 ch).  Gallery:
  **net-new**. Independence: **third-party**.

seq:
  - id: header_len
    type: u2
    valid:
      eq: 814
    doc: Header size minus this length word (0x0330 - 2).
  - id: reserved1
    size: 4
    doc: Unused header prefix.
  - id: frame_count
    type: u2
    doc: Declared TOC block count (not an ffprobe stream field).
  - id: reserved2
    size: 4
    doc: Unused word before geometry.
  - id: width
    type: u2
    valid:
      min: 1
      max: 2048
    doc: Frame width in pixels.
  - id: height
    type: u2
    valid:
      min: 1
      max: 2048
    doc: Frame height in pixels.
  - id: reserved3
    size: 2
    doc: Unused word before frames-per-block.
  - id: frames_per_block
    type: u2
    doc: Frame records per TOC block.
  - id: reserved4
    size: 4
    doc: Unused word before the Indeo tag.
  - id: indeo_tag
    size: 3
    doc: ASCII iv3 selects Indeo 3; anything else is VMD video.
  - id: reserved_mid
    size: 777
    doc: Remainder of the header through offset 803.
  - id: sample_rate
    type: u2
    valid:
      min: 1
    doc: Audio sample rate in Hz (0 would mean no audio).
  - id: block_align
    type: u2
    valid:
      min: 1
    doc: Block align.  High bit 0x8000 means 16-bit samples.
  - id: sound_buffers
    type: u2
    doc: Audio buffers in the first sound chunk.
  - id: reserved5
    type: u1
    doc: Unused byte before the channel flags.
  - id: channel_flags
    type: u1
    doc: Bit 0x80 or 0x02 means stereo; otherwise mono.
  - id: toc_offset
    type: u4
    doc: Absolute file offset of the TOC (not walked here).
  - id: rest
    size-eos: true
    doc: TOC and frame payload (uninterpreted).

instances:
  is_indeo3:
    value: >
      indeo_tag[0] == 0x69 and indeo_tag[1] == 0x76 and
      indeo_tag[2] == 0x33
    doc: True when bytes 24-26 are ASCII iv3.
  bits_per_sample:
    value: '(block_align & 0x8000) != 0 ? 16 : 8'
    doc: 16 if block_align has 0x8000 set, else 8.
  audio_channels:
    value: >
      ((channel_flags & 0x80) != 0) or ((channel_flags & 0x02) != 0) ? 2 : 1
    doc: Stereo if flags 0x80 or 0x02, else mono.
  audio_bit_rate:
    value: sample_rate * bits_per_sample * audio_channels
    doc: ffprobe audio bit_rate (rate × bits × channels).
  codec_label:
    value: 'is_indeo3 ? "indeo3" : "vmdvideo"'
    doc: ffprobe video codec_name from the iv3 tag.
  audio_codec_label:
    value: '"vmdaudio"'
    doc: ffprobe audio codec_name.  VMD audio is always VMDAUDIO.

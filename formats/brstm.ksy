meta:
  id: brstm
  title: Nintendo BRSTM header
  endian: be
doc: |
  Nintendo BRSTM (Binary Revolution Stream) — header unit.

  Layout (FFmpeg 6.1.1 libavformat/brstm.c, big-endian
  BRSTM path; not BFSTM/CSTM):

  * RSTM + BOM 0xFEFF + version + declared file size
    (lies on this truncated FATE partial)
  * header_size (u16) skips to the HEAD chunk
  * HEAD info at h1offset: codec, loop flag, channels,
    sample rate (u16), loop start, sample count

  Codec 2 is ADPCM THP.  Loop start is published as
  microseconds (samples × 1e6 / rate), matching
  ffprobe's format tag.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `brstm/lozswd_partial.brstm` (adpcm_thp 32000 Hz/6 ch,
  2655726 samples).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: magic
    contents: RSTM
    doc: BRSTM signature.
  - id: bom
    type: u2
    valid:
      eq: 0xfeff
    doc: Byte-order mark.  0xFEFF = big-endian (this path).
  - id: version_major
    type: u1
    doc: Major version (1 in the FATE head).
  - id: version_minor
    type: u1
    doc: Minor version (0 in the FATE head).
  - id: file_size
    type: u4
    doc: Declared file size.  Lies on truncated FATE partials.
  - id: header_size
    type: u2
    valid:
      min: 14
    doc: Offset of the HEAD chunk from file start.
  - id: header_pad
    size: header_size - 14
    doc: Remainder of the RSTM preamble before HEAD.
  - id: head_tag
    contents: HEAD
    doc: HEAD chunk tag.
  - id: head_size
    type: u4
    valid:
      min: 40
    doc: HEAD chunk size including the tag.
  - id: head_unknown
    size: 4
    doc: Unused HEAD word.
  - id: h1_offset
    type: u4
    doc: Offset of the audio-info record from HEAD.
  - id: head_skip
    size: 12
    doc: Unused HEAD words before the coefficient offset.
  - id: coeff_offset
    type: u4
    doc: Coefficient-table offset (unused here).
  - id: skip_to_info
    size: h1_offset + 8 - 32
    doc: Seek to HEAD+h1_offset+8 (0 when h1_offset is 0x18).
  - id: codec
    type: u1
    valid:
      any-of: [0, 1, 2]
    doc: 0 = PCM s8, 1 = PCM s16be, 2 = ADPCM THP.
  - id: loop_flag
    type: u1
    doc: Non-zero if the stream loops.
  - id: channels
    type: u1
    valid:
      min: 1
    doc: Channel count.
  - id: info_pad
    type: u1
    doc: Alignment pad after channels.
  - id: sample_rate
    type: u2
    valid:
      min: 1
    doc: Sample rate in Hz.
  - id: rate_pad
    type: u2
    doc: Alignment pad after sample rate.
  - id: loop_start_samples
    type: u4
    doc: Loop start in samples (0 if not looping).
  - id: num_samples
    type: u4
    valid:
      min: 1
    doc: Declared sample count (ffprobe duration_ts).
  - id: rest
    size-eos: true
    doc: Remaining HEAD fields, ADPC, and DATA (uninterpreted).

instances:
  loop_start_us:
    value: loop_start_samples * 1000000 / sample_rate
    doc: Loop start in microseconds (ffprobe format tag).
  codec_label:
    value: 'codec == 2 ? "adpcm_thp" : (codec == 1 ? "pcm_s16be_planar" : "pcm_s8_planar")'
    doc: ffprobe codec_name from the HEAD codec byte.

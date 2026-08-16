meta:
  id: bfstm
  title: Nintendo BFSTM header
  endian: be
doc: |
  Nintendo BFSTM (Binary Cafe Stream) — header unit.

  Layout (FFmpeg 6.1.1 libavformat/brstm.c, BFSTM path;
  not BRSTM):

  * FSTM + BOM 0xFEFF (big-endian path)
  * u16 header size, unknown 0x00030000, file size
  * section table (flag 0x4000 = INFO)
  * INFO: codec, loop flag, channels, u32 sample rate
    (unlike BRSTM's u16), loop start, sample count

  Codec 2 on a big-endian file is ADPCM THP.  Loop start
  is published as microseconds (samples × 1e6 / rate).

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `bfstm/spl-forest-day.bfstm` (adpcm_thp 32000 Hz/1 ch,
  226499 samples).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: magic
    contents: FSTM
    doc: BFSTM signature.  CSTM is the little-endian sibling.
  - id: bom
    type: u2
    valid:
      eq: 0xfeff
    doc: Byte-order mark.  0xFEFF = big-endian (this path).
  - id: header_size
    type: u2
    valid:
      min: 20
    doc: Size of the FSTM header including the section table.
  - id: unknown_const
    type: u4
    doc: Constant 0x00030000 skipped by the demuxer.
  - id: file_size
    type: u4
    doc: Declared file size.
  - id: num_sections
    type: u2
    valid:
      min: 1
    doc: Number of header section entries.
  - id: section_pad
    type: u2
    doc: Alignment pad after the section count.
  - id: sections
    type: section
    repeat: expr
    repeat-expr: num_sections
    doc: Section table (INFO / SEEK / DATA / REGN).
  - id: header_pad
    size: header_size - 20 - num_sections * 12
    doc: Remainder of the FSTM header before INFO.
  - id: info_tag
    contents: INFO
    doc: INFO chunk tag.
  - id: info_size
    type: u4
    valid:
      min: 40
    doc: INFO chunk size including the tag.
  - id: info_unknown
    size: 4
    doc: Unused INFO word.
  - id: h1_offset
    type: u4
    doc: Offset of the audio-info record from INFO.
  - id: info_skip
    size: 12
    doc: Unused INFO words before the coefficient offset.
  - id: coeff_offset
    type: u4
    doc: Coefficient-table offset (unused here).
  - id: skip_to_info
    size: h1_offset + 8 - 32
    doc: Seek to INFO+h1_offset+8 (0 when h1_offset is 0x18).
  - id: codec
    type: u1
    valid:
      any-of: [0, 1, 2]
    doc: 0 = PCM s8, 1 = PCM s16, 2 = ADPCM THP.
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
    type: u4
    valid:
      min: 1
    doc: Sample rate in Hz (32-bit on BFSTM, unlike BRSTM).
  - id: loop_start_samples
    type: u4
    doc: Loop start in samples (0 if the loop point is the start).
  - id: num_samples
    type: u4
    valid:
      min: 1
    doc: Declared sample count (ffprobe duration_ts).
  - id: rest
    size-eos: true
    doc: Remaining INFO fields, SEEK, and DATA (uninterpreted).

types:
  section:
    seq:
      - id: flag
        type: u2
        doc: 0x4000 INFO, 0x4001 SEEK, 0x4002 DATA, 0x4003 REGN.
      - id: pad
        type: u2
        doc: Alignment pad after the flag.
      - id: offset
        type: u4
        doc: Absolute offset of this section.
      - id: len_section
        type: u4
        doc: Declared section size.

instances:
  loop_start_us:
    value: loop_start_samples * 1000000 / sample_rate
    doc: Loop start in microseconds (ffprobe format tag).
  codec_label:
    value: 'codec == 2 ? "adpcm_thp" : (codec == 1 ? "pcm_s16be_planar" : "pcm_s8_planar")'
    doc: ffprobe codec_name from the INFO codec byte (BE path).

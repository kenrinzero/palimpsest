meta:
  id: psxstr
  title: Sony PlayStation STR header
  endian: le
doc: |
  Sony PlayStation STR (CD-XA) — header unit.

  Layout (FFmpeg 6.1.1 libavformat/psxstr.c):

  * Optional 0x2C-byte RIFF/CDXA wrapper (present here)
  * Concatenated 2352-byte CD sectors.  This unit walks
    from the FFmpeg 0x2C origin through the first audio
    sector (video sectors come first).
  * Video (DATA/VIDEO, type & 0x0E is 0x08 or 0x02):
    u16le width/height at sector +0x28/+0x2A.  Codec
    is always MDEC.  15 fps is a demuxer constant.
  * Audio (type & 0x0E is 0x04): coding byte at +0x13
    bit 0 = stereo, bit 2 = 18900 Hz else 37800 Hz.
    Codec is always ADPCM XA.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `psx-str/abc000_cut.str` (320×160 mdec + adpcm_xa
  37800 Hz/2 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: riff_tag
    contents: RIFF
    doc: RIFF wrapper tag.
  - id: riff_size
    type: u4
    doc: Declared RIFF size (0 on this FATE head).
  - id: riff_type
    contents: CDXA
    doc: CD-XA form type.
  - id: riff_pad
    size: 0x2c - 12
    doc: Remainder of the 0x2C-byte RIFF header FFmpeg skips.
  - id: sectors
    type: cd_sector
    size: 2352
    repeat: until
    repeat-until: _.is_audio
    doc: CD sectors through the first audio sector.
  - id: rest
    size-eos: true
    doc: Remaining sectors (uninterpreted).

instances:
  width:
    value: sectors.first.frame_width
    doc: Video width from the first DATA/VIDEO sector.
  height:
    value: sectors.first.frame_height
    doc: Video height from the first DATA/VIDEO sector.
  audio_sample_rate:
    value: sectors.last.sample_rate
    doc: XA sample rate from the first audio sector.
  audio_channels:
    value: sectors.last.xa_channels
    doc: XA channel count from the first audio sector.
  codec_label:
    value: '"mdec"'
    doc: ffprobe video codec_name.  STR video is always MDEC.
  audio_codec_label:
    value: '"adpcm_xa"'
    doc: ffprobe audio codec_name.  STR audio is always XA.

types:
  cd_sector:
    seq:
      - id: skip_to_channel
        size: 0x11
        doc: Sync, MSF, and mode (uninterpreted).
      - id: channel
        type: u1
        valid:
          max: 31
        doc: XA channel number (0–31).
      - id: xa_type
        type: u1
        doc: XA submode.  Bits 1–3 select data/video/audio.
      - id: coding
        type: u1
        doc: XA coding info (channels and rate for audio).
      - id: skip_to_frame
        size: 8
        doc: Subheader copy and unused bytes through +0x1B.
      - id: current_sector
        type: u2
        doc: Index of this chunk inside the video frame.
      - id: sector_count
        type: u2
        doc: Number of sectors in the video frame.
      - id: skip_to_size
        size: 4
        doc: Unused bytes through +0x23.
      - id: frame_size
        type: u4
        doc: Declared video frame size.
      - id: frame_width
        type: u2
        doc: Video width (meaningful on DATA/VIDEO sectors).
      - id: frame_height
        type: u2
        doc: Video height (meaningful on DATA/VIDEO sectors).
      - id: payload
        size-eos: true
        doc: Remainder of the 2352-byte sector.
    instances:
      type_bits:
        value: xa_type & 14
        doc: xa_type masked with CDXA_TYPE_MASK (0x0E).
      is_audio:
        value: type_bits == 4
        doc: CDXA_TYPE_AUDIO.
      is_video:
        value: 'type_bits == 8 or type_bits == 2'
        doc: CDXA_TYPE_DATA or CDXA_TYPE_VIDEO.
      sample_rate:
        value: 'coding & 4 != 0 ? 18900 : 37800'
        doc: 18900 Hz if coding bit 2, else 37800 Hz.
      xa_channels:
        value: (coding & 1) + 1
        doc: Stereo if coding bit 0, else mono.

meta:
  id: film_cpk
  title: Sega FILM / CPK header, FDSC, and STAB
  endian: be
doc: |
  Sega FILM (Saturn/Dreamcast .cpk) container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/segafilm.c, Saturn path):

  * 16-byte FILM header (magic, data offset, version, reserved)
  * 32-byte FDSC (fourcc, height, width, bpp, audio params)
  * STAB (base clock, sample count, 16-byte records)
  * packet payload at `data_offset` (Cinepak or raw video; uninterpreted)

  Version 0 is the Lemmings 20-byte FDSC path and is rejected here.
  This unit's fixture is video-only, so `audio_channels` must be 0 and
  `num_frames` is the STAB sample count (every record is a video frame).

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 32×24
  cinepak clip at 15 fps, 8 frames.  Gallery: **net-new**.
  Independence: **self-generated**.

seq:
  - id: magic
    contents: FILM
    doc: Sega FILM signature.
  - id: data_offset
    type: u4
    valid:
      min: 64
    doc: Absolute file offset of the first packet (after FILM+FDSC+STAB).
  - id: version
    type: u4
    valid:
      expr: _ != 0
    doc: |
      Version word.  Saturn encodes ASCII "1.09" (0x312E3039).  Zero
      selects the Lemmings 20-byte FDSC layout, which this unit does not
      parse.
  - id: reserved
    type: u4
    doc: Unused FILM header word (zero in the generated fixture).
  - id: fdsc
    type: fdsc_chunk
    doc: Film description (codec fourcc and geometry).
  - id: stab
    type: stab_chunk
    doc: Sample table (clock, count, per-sample records).
  - id: packets
    size-eos: true
    doc: Uninterpreted video packets starting at data_offset.

types:
  fdsc_chunk:
    seq:
      - id: tag
        contents: FDSC
        doc: Film-description chunk tag.
      - id: chunk_size
        type: u4
        valid:
          eq: 32
        doc: Saturn FDSC is a fixed 32-byte chunk (tag through reserved).
      - id: fourcc
        type: u4
        valid:
          any-of: [0x63766964, 0x72617720]
        doc: Video fourcc.  0x63766964 = cvid (Cinepak), 0x72617720 = raw .
      - id: height
        type: u4
        valid:
          min: 1
        doc: Frame height in pixels.
      - id: width
        type: u4
        valid:
          min: 1
        doc: Frame width in pixels.
      - id: bits_per_pixel
        type: u1
        doc: Bits per pixel (used by the raw-video path; 24 in FFmpeg).
      - id: audio_channels
        type: u1
        valid:
          eq: 0
        doc: Channel count.  This unit requires 0 (video-only fixture).
      - id: audio_bits
        type: u1
        doc: Audio bit depth when audio_channels > 0.
      - id: audio_codec_id
        type: u1
        doc: 2 = ADPCM ADX; other non-zero values select PCM variants.
      - id: audio_sample_rate
        type: u2
        doc: Audio sample rate in Hz when audio is present.
      - id: fdsc_pad
        size: 6
        doc: Remaining FDSC bytes (zero in the generated fixture).

  stab_chunk:
    seq:
      - id: tag
        contents: STAB
        doc: Sample-table chunk tag.
      - id: chunk_size
        type: u4
        valid:
          min: 16
        doc: STAB size in bytes (header plus 16 bytes per sample).
      - id: base_clock
        type: u4
        valid:
          min: 1
        doc: Video time base denominator (ffprobe r_frame_rate numerator).
      - id: num_samples
        type: u4
        valid:
          min: 1
        doc: Number of STAB records that follow.
      - id: samples
        type: sample_record
        repeat: expr
        repeat-expr: num_samples
        doc: Per-sample offset, size, pts/flags.

  sample_record:
    seq:
      - id: packet_offset
        type: u4
        doc: Packet start relative to FILM data_offset.
      - id: packet_size
        type: u4
        doc: Packet size in bytes.
      - id: pts_and_flags
        type: u4
        doc: |
          0xFFFFFFFF marks an audio sample.  Otherwise the low 31 bits
          are the video PTS and bit 31 marks a non-keyframe.
      - id: rec_pad
        type: u4
        doc: Trailing STAB record word (1 in the generated fixture).

instances:
  width:
    value: fdsc.width
    doc: Frame width from FDSC.
  height:
    value: fdsc.height
    doc: Frame height from FDSC.
  num_frames:
    value: stab.num_samples
    doc: Video frame count (STAB length on this video-only unit).
  fps_num:
    value: stab.base_clock
    doc: Frame-rate numerator (FILM base clock).
  fps_den:
    value: 1
    doc: Frame-rate denominator.  FILM time base is 1 / base_clock.
  walked_sample_count:
    value: stab.samples.size
    doc: Number of STAB records actually walked.
  codec_label:
    value: >
      fdsc.fourcc == 0x63766964 ? "cinepak" :
      fdsc.fourcc == 0x72617720 ? "rawvideo" :
      "unknown"
    doc: ffprobe codec_name derived from the FDSC fourcc.

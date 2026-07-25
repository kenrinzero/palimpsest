meta:
  id: bink
  title: Bink (BIK) header with audio tracks and frame offsets
  endian: le
doc: |
  RAD Game Tools Bink container — depth unit (supported BIK revisions
  b, f, g, h, i, and k).

  Layout (FFmpeg 6.1.1 libavformat/bink.c):

  * 44-byte base header (signature, size-8, frame counts, dimensions,
    fps, video flags, audio-track count)
  * optional u4 after the base header for revision `k`
  * per audio track: max-decoded-size u4 table, then rate/flags pairs,
    then track-id u4 table
  * frame offset table of `num_frames + 1` little-endian u4 values;
    low bit marks keyframe, remaining bits are the absolute file offset

  Audio flag bits used here: 0x2000 stereo, 0x1000 DCT (else RDFT).

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE `RazOnBull.bik`
  (BIKi, 640×480 @ 30 fps, 31 frames, binkvideo + binkaudio_dct
  44100 Hz/2 ch).  Gallery: **net-new**. Independence: **third-party**.

seq:
  - id: signature_prefix
    contents: 'BIK'
    doc: Bink signature prefix.
  - id: version
    type: u1
    valid:
      any-of: [0x62, 0x66, 0x67, 0x68, 0x69, 0x6b]
    doc: Supported BIK revision letter (b, f, g, h, i, or k).
  - id: file_size_minus_8
    type: u4
    doc: Stored total file size minus the first 8 bytes.
  - id: num_frames
    type: u4
    valid:
      min: 1
    doc: Total frame count.
  - id: largest_frame_size
    type: u4
    doc: Size in bytes of the largest single frame.
  - id: frame_count_word_2
    type: u4
    doc: Second frame-count word; equals num_frames in the proven BIKi fixture.
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
  - id: fps_num
    type: u4
    valid:
      min: 1
    doc: Frame rate numerator.
  - id: fps_den
    type: u4
    valid:
      min: 1
    doc: Frame rate denominator (typically 1 for integer rates).
  - id: video_flags
    type: u4
    doc: Video stream flags; interpretation varies by Bink revision.
  - id: num_audio_tracks
    type: u4
    doc: Number of per-track audio records following the base header.
  - id: unknown_k_field
    type: u4
    if: version == 0x6b
    doc: Extra u4 present only on BIK revision k (skipped by FFmpeg).
  - id: audio_max_decoded_sizes
    type: u4
    repeat: expr
    repeat-expr: num_audio_tracks
    doc: Per-track maximum decoded audio buffer size (bytes).
  - id: audio_tracks
    type: audio_track
    repeat: expr
    repeat-expr: num_audio_tracks
    doc: Per-track sample rate and flags.
  - id: audio_ids
    type: u4
    repeat: expr
    repeat-expr: num_audio_tracks
    doc: Per-track stream identifiers.
  - id: frame_offsets
    type: frame_offset
    repeat: expr
    repeat-expr: num_frames + 1
    doc: |
      Frame index table — num_frames entries plus a trailing end-of-file
      sentinel offset.  Low bit of each word is the keyframe flag.

types:
  audio_track:
    seq:
      - id: sample_rate
        type: u2
        valid:
          min: 1
        doc: Audio sample rate in Hz.
      - id: flags
        type: u2
        doc: |
          Track flags.  0x2000 = stereo, 0x1000 = DCT (Bink Audio DCT),
          0x4000 = 16-bit related; absence of 0x1000 implies RDFT.
    instances:
      is_stereo:
        value: (flags & 0x2000) != 0
      is_dct:
        value: (flags & 0x1000) != 0
      channels:
        value: 'is_stereo ? 2 : 1'
      codec_label:
        value: 'is_dct ? "binkaudio_dct" : "binkaudio_rdft"'
        doc: ffprobe audio codec_name for this track's flags.

  frame_offset:
    seq:
      - id: raw
        type: u4
        doc: Packed offset word (low bit = keyframe, rest = absolute offset).
    instances:
      is_keyframe:
        value: (raw & 1) != 0
        doc: Keyframe when the low bit is set.
      pos:
        value: raw & 4294967294
        doc: Absolute file offset of the frame (low bit cleared).

instances:
  file_size:
    value: file_size_minus_8 + 8
    doc: Total file size in bytes.

  walked_frame_offset_count:
    value: frame_offsets.size
    doc: Offset-table entry count (num_frames + 1 by construction).

  primary_audio:
    value: audio_tracks[0]
    doc: First audio track when num_audio_tracks > 0 (FATE fixture has one).
    if: num_audio_tracks > 0

  audio_sample_rate:
    value: primary_audio.sample_rate
    if: num_audio_tracks > 0

  audio_channels:
    value: primary_audio.channels
    if: num_audio_tracks > 0

  audio_codec_label:
    value: primary_audio.codec_label
    if: num_audio_tracks > 0

  first_frame_pos:
    value: frame_offsets[0].pos
    doc: Absolute offset of frame 0 from the index table.

  codec_label:
    value: '"binkvideo"'
    doc: |
      ffprobe codec name — Bink containers always carry the Bink
      video codec.  Constant for this format.

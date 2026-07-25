meta:
  id: smk
  title: Smacker (SMK) header, audio tracks, and per-frame tables
  endian: le
doc: |
  RAD Game Tools Smacker video file (SMK2/SMK4) — header depth unit.

  Layout (matches FFmpeg 6.1.1 libavformat/smacker.c and MultimediaWiki):

  * 24-byte identity block (signature, dimensions, stored frame count,
    signed PTS increment, flags)
  * seven u4 audio-size slots (historical; demuxers skip them)
  * treesize plus four Huffman-tree size words (mmap/mclr/full/type)
  * seven audio tracks: little-endian 24-bit sample rate + flag byte
  * u4 header pad
  * per-frame size table (`total_frames` × u4) and type/flags table
    (`total_frames` × u1)

  Frame payload and Huffman tree bytes after the type table are left
  uninterpreted — this unit proves container depth, not codec math.

  Audio flag bits (FFmpeg `SAudFlags`):
    0x80 PACKED → smackaudio, 0x20 16-bit, 0x10 stereo,
    0x08 Bink RDFT, 0x04 Bink DCT.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE `wetlogo.smk`
  (320×200, 100 frames, smackvideo + smackaudio 22050 Hz/1 ch).
  Gallery status: **net-new**. Independence: **third-party**.

seq:
  - id: signature_prefix
    contents: 'SMK'
    doc: Smacker signature prefix.
  - id: version
    type: u1
    valid:
      any-of: [0x32, 0x34]
    doc: ASCII "2" or "4", selecting SMK2 or SMK4.
  - id: width
    type: u4
    doc: Frame width in pixels.
  - id: height
    type: u4
    doc: Frame height in pixels.
  - id: stored_frames
    type: u4
    doc: Stored frame count, excluding an optional ring frame.
  - id: pts_inc
    type: s4
    doc: |
      Signed PTS increment per frame.  Smacker uses a 100,000-unit internal
      time base.  Positive values are multiplied by 100; negative values
      use their absolute value directly.
  - id: flags
    type: u4
    doc: |
      Flags: bit 0 = ring frame present, bit 1 = Y-interlaced,
      bit 2 = Y-doubled.
  - id: audio_sizes
    type: u4
    repeat: expr
    repeat-expr: 7
    doc: |
      Historical per-track maximum audio chunk sizes.  FFmpeg skips this
      28-byte block; retained so the following tree and audio fields stay
      at their true file offsets.
  - id: treesize
    type: u4
    doc: Byte length of the Huffman tree blob that follows the frame tables.
  - id: mmap_size
    type: u4
    doc: Size of the mmap Huffman tree (codec extradata).
  - id: mclr_size
    type: u4
    doc: Size of the mclr Huffman tree (codec extradata).
  - id: full_size
    type: u4
    doc: Size of the full Huffman tree (codec extradata).
  - id: type_size
    type: u4
    doc: Size of the type Huffman tree (codec extradata).
  - id: audio_tracks
    type: audio_track
    repeat: expr
    repeat-expr: 7
    doc: Up to seven audio tracks; a zero sample rate means the slot is unused.
  - id: header_pad
    type: u4
    doc: Fixed four-byte pad ending the 104-byte fixed header region.
  - id: frame_sizes
    type: u4
    repeat: expr
    repeat-expr: total_frames
    doc: |
      Per-frame payload sizes.  The low bit marks a keyframe for demux
      indexing (FFmpeg); the full u4 is still the byte stride to the next
      frame.
  - id: frame_types
    type: u1
    repeat: expr
    repeat-expr: total_frames
    doc: |
      Per-frame type/flag bytes (palette bit 0, audio-track presence bits
      in the upper bits).  Semantics of individual bits beyond count
      agreement are not asserted by this unit.

types:
  audio_track:
    doc: |
      One Smacker audio track descriptor: 24-bit little-endian sample rate
      packed with a flag byte in a single u4 (rate in bits 0–23, flags in
      bits 24–31), matching FFmpeg's avio_rl24 + avio_r8 read order.
    seq:
      - id: rate_and_flags
        type: u4
    instances:
      sample_rate:
        value: rate_and_flags & 0xffffff
        doc: Sample rate in Hz; zero means the track slot is unused.
      flags:
        value: (rate_and_flags >> 24) & 0xff
        doc: Audio flag byte (PACKED/16BIT/STEREO/Bink variants).
      is_packed:
        value: (flags & 0x80) != 0
        doc: SMK_AUD_PACKED — Smacker ADPCM rather than raw PCM.
      is_16bit:
        value: (flags & 0x20) != 0
        doc: SMK_AUD_16BITS.
      is_stereo:
        value: (flags & 0x10) != 0
        doc: SMK_AUD_STEREO.
      is_bink_rdft:
        value: (flags & 0x08) != 0
        doc: SMK_AUD_BINKAUD — Bink RDFT audio.
      is_bink_dct:
        value: (flags & 0x04) != 0
        doc: SMK_AUD_USEDCT — Bink DCT audio.
      channels:
        value: 'is_stereo ? 2 : 1'
        doc: Channel count derived from the stereo flag (mono default).
      codec_label:
        value: |
          is_bink_rdft ? "binkaudio_rdft" : (
            is_bink_dct ? "binkaudio_dct" : (
              is_packed ? "smackaudio" : (
                is_16bit ? "pcm_s16le" : "pcm_u8"
              )
            )
          )
        doc: ffprobe codec_name mapping for this track's flag combination.

instances:
  total_frames:
    value: stored_frames + (flags & 1)
    doc: Stored frames plus the optional ring frame indicated by flags bit 0.

  frame_duration_units:
    value: 'pts_inc > 0 ? pts_inc * 100 : 0 - pts_inc'
    doc: Frame duration numerator on Smacker's 100,000-unit time base.

  walked_frame_count:
    value: frame_sizes.size
    doc: |
      Number of frame-size table entries actually walked.  Equals
      total_frames by construction of the repeat-expr; listed under
      self_checked as declared-count == walked-count.

  primary_audio:
    value: audio_tracks[0]
    doc: |
      First audio-track slot.  FFmpeg creates audio streams for every
      non-zero rate in order; on FATE wetlogo.smk only slot 0 is live,
      so stream 1 matches this track.

  audio_sample_rate:
    value: primary_audio.sample_rate
    doc: Primary audio sample rate (Hz) for differential vs ffprobe stream 1.

  audio_channels:
    value: primary_audio.channels
    doc: Primary audio channel count for differential vs ffprobe stream 1.

  audio_codec_label:
    value: primary_audio.codec_label
    doc: Primary audio codec_name for differential vs ffprobe stream 1.

  codec_label:
    value: '"smackvideo"'
    doc: |
      ffprobe codec name — Smacker containers always carry the Smacker
      video codec.  The codec name is constant for this format.

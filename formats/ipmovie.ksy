meta:
  id: ipmovie
  title: Interplay MVE header with video and audio init opcodes
  endian: le
doc: |
  Interplay MVE (Movie) container — header depth unit.

  Layout (FFmpeg 6.1.1 libavformat/ipmovie.c):

  * 26-byte fixed signature/magic header
  * size-delimited chunks, each carrying a stream of 4-byte-preamble
    opcodes (`len_body` u2, type u1, version u1, then `len_body` bytes)

  This depth unit requires the first chunk to be INIT_VIDEO (0x0002) and
  walks its opcodes through INIT_VIDEO_BUFFERS (0x05).  Stored width and
  height are each divided by 8 — real dimensions are `stored * 8`.

  It then requires the next chunk to be INIT_AUDIO (0x0000) and walks
  that chunk's opcodes through INIT_AUDIO_BUFFERS (0x03).  Per FFmpeg:

  * sample rate = u2le at payload offset 4
  * flags = u2le at payload offset 2
    - bit 0: stereo (channels = bit + 1)
    - bit 1: 16-bit samples
    - bit 2 + opcode version 1: Interplay DPCM
  * otherwise PCM s16le / u8 from the bit-depth flag

  Later video/audio frame chunks remain uninterpreted.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `descent3-level5-16bit-partial.mve` (640×320, interplayvideo +
  interplay_dpcm 44100 Hz/2 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: signature
    contents: 'Interplay MVE File'
    doc: Interplay MVE text signature.
  - id: dos_eof_1
    contents: [0x1a, 0x00]
    doc: DOS EOF marker and NUL terminator.
  - id: dos_eof_2
    contents: [0x1a, 0x00]
    doc: Second DOS EOF marker and NUL terminator.
  - id: magic_0100
    type: u2
    valid: 0x0100
    doc: Fixed 0x0100 signature word.
  - id: magic_1133
    type: u2
    valid: 0x1133
    doc: Fixed 0x1133 signature word.
  - id: len_first_chunk_data
    type: u2
    valid:
      min: 4
    doc: Size in bytes of the first chunk's opcode stream (at least one opcode preamble).
  - id: first_chunk_type
    type: u2
    valid: 0x0002
    doc: First chunk type, required to be INIT_VIDEO (0x0002).
  - id: first_chunk_data
    size: len_first_chunk_data
    type: opcode_stream_to_video_buffers
    doc: Bounded opcode stream for the first INIT_VIDEO chunk.
  - id: len_second_chunk_data
    type: u2
    valid:
      min: 4
    doc: Size in bytes of the second chunk's opcode stream (at least one opcode preamble).
  - id: second_chunk_type
    type: u2
    valid: 0x0000
    doc: Second chunk type, required to be INIT_AUDIO (0x0000) for this depth unit.
  - id: second_chunk_data
    size: len_second_chunk_data
    type: opcode_stream_to_audio_buffers
    doc: Bounded opcode stream for the INIT_AUDIO chunk.

types:
  opcode_stream_to_video_buffers:
    seq:
      - id: opcodes
        type: opcode
        repeat: until
        repeat-until: _.opcode_type == 0x05
        doc: Opcodes through the first INIT_VIDEO_BUFFERS record.

  opcode_stream_to_audio_buffers:
    seq:
      - id: opcodes
        type: opcode
        repeat: until
        repeat-until: _.opcode_type == 0x03
        doc: Opcodes through the first INIT_AUDIO_BUFFERS record.

  opcode:
    seq:
      - id: len_body
        type: u2
        doc: Opcode payload size, excluding this four-byte preamble.
      - id: opcode_type
        type: u1
      - id: opcode_version
        type: u1
      - id: body
        size: len_body
        type: opcode_payload
        doc: Bounded opcode payload.

  opcode_payload:
    seq:
      - id: init_video_buffers
        type: init_video_buffers
        if: _parent.opcode_type == 0x05
        doc: Parsed INIT_VIDEO_BUFFERS payload.
      - id: init_audio_buffers
        type: init_audio_buffers
        if: _parent.opcode_type == 0x03
        doc: Parsed INIT_AUDIO_BUFFERS payload.
      - id: uninterpreted
        size-eos: true
        if: (_parent.opcode_type != 0x05) and (_parent.opcode_type != 0x03)
        doc: Payload bytes for opcodes outside this unit's scope.

  init_video_buffers:
    seq:
      - id: stored_width
        type: u2
        doc: Frame width divided by 8.
      - id: stored_height
        type: u2
        doc: Frame height divided by 8.
      - id: remaining
        size-eos: true
        doc: Version-specific fields after the required dimensions.

  init_audio_buffers:
    doc: |
      INIT_AUDIO_BUFFERS payload layout used by FFmpeg:
      bytes 0–1 reserved/unknown, bytes 2–3 flags, bytes 4–5 sample rate.
      Remaining bytes (version-dependent, up to 10 total) are retained
      but not asserted.
    seq:
      - id: unknown0
        type: u2
        doc: First payload word; not used by FFmpeg for stream params.
      - id: flags
        type: u2
        doc: |
          Bit 0 = stereo, bit 1 = 16-bit, bit 2 = compressed (with
          opcode version 1 → Interplay DPCM).
      - id: sample_rate
        type: u2
        doc: Audio sample rate in Hz.
      - id: remaining
        size-eos: true
        doc: Optional trailing fields of longer INIT_AUDIO_BUFFERS payloads.

    instances:
      channels:
        value: (flags & 1) + 1
        doc: Channel count — mono when bit 0 clear, stereo when set.
      bits_per_sample:
        value: (((flags >> 1) & 1) + 1) * 8
        doc: 8 or 16 bits per sample from flags bit 1.
      is_interplay_dpcm:
        value: (_parent._parent.opcode_version == 1) and ((flags & 4) != 0)
        doc: Compressed Interplay DPCM when version is 1 and flags bit 2 is set.
      codec_label:
        value: |
          is_interplay_dpcm ? "interplay_dpcm" : (
            bits_per_sample == 16 ? "pcm_s16le" : "pcm_u8"
          )
        doc: ffprobe audio codec_name for this flag/version combination.

instances:
  video_buffers:
    value: first_chunk_data.opcodes.last.body.init_video_buffers
    doc: Parsed INIT_VIDEO_BUFFERS payload found in the first chunk.

  video_width:
    value: video_buffers.stored_width * 8
    doc: Actual frame width in pixels (stored value × 8).

  video_height:
    value: video_buffers.stored_height * 8
    doc: Actual frame height in pixels (stored value × 8).

  audio_buffers:
    value: second_chunk_data.opcodes.last.body.init_audio_buffers
    doc: Parsed INIT_AUDIO_BUFFERS payload found in the INIT_AUDIO chunk.

  audio_sample_rate:
    value: audio_buffers.sample_rate
    doc: Primary audio sample rate for differential vs ffprobe stream 1.

  audio_channels:
    value: audio_buffers.channels
    doc: Primary audio channel count for differential vs ffprobe stream 1.

  audio_codec_label:
    value: audio_buffers.codec_label
    doc: Primary audio codec_name for differential vs ffprobe stream 1.

  codec_label:
    value: '"interplayvideo"'
    doc: |
      ffprobe codec name — MVE containers always carry the Interplay
      video codec.  Constant for this format.

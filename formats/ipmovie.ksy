meta:
  id: ipmovie
  title: Interplay MVE video file header
  endian: le
doc: |
  Interplay MVE (Movie) container header.

  The file uses a 26-byte fixed header followed by a chunk/opcode stream.
  Dimensions are carried inside the INIT_VIDEO_BUFFERS opcode (0x05) of
  the first INIT_VIDEO chunk (0x0002).  The stored width and height are
  each divided by 8 — the real dimensions are `stored * 8`.

  The first chunk is required to be INIT_VIDEO.  This header unit walks that
  chunk's declared opcode records until it finds INIT_VIDEO_BUFFERS (0x05),
  whose first four data bytes carry width and height divided by 8.  A later
  depth unit can model the remaining chunk and full-file opcode stream.

  Proven against ffprobe 6.1.1-3ubuntu5 on a FATE-suite sample
  (`descent3-level5-16bit-partial.mve`, 640×320, interplayvideo +
  interplay_dpcm 44100 Hz/2 ch).  Gallery status: **net-new**.
  Independence regime: **third-party** (FATE-suite bytes).

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
    doc: Size in bytes of the first chunk's opcode stream.
  - id: first_chunk_type
    type: u2
    valid: 0x0002
    doc: First chunk type, required to be INIT_VIDEO (0x0002).
  - id: first_chunk_data
    size: len_first_chunk_data
    type: init_video_chunk
    doc: Bounded opcode stream for the first INIT_VIDEO chunk.

types:
  init_video_chunk:
    seq:
      - id: opcodes
        type: opcode
        repeat: until
        repeat-until: _.opcode_type == 0x05
        doc: Opcodes through the first INIT_VIDEO_BUFFERS record.

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
      - id: uninterpreted
        size-eos: true
        if: _parent.opcode_type != 0x05
        doc: Payload bytes for opcodes outside this header unit's scope.

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

  codec_label:
    value: '"interplayvideo"'
    doc: |
      ffprobe codec name — MVE containers always carry the Interplay
      video codec.  Constant for this format.

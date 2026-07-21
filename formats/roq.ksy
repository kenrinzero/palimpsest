meta:
  id: roq
  title: Id Software RoQ video file header
  endian: le
doc: |
  Id Software RoQ video container.

  The file begins with an 8-byte header (signature 0x1084, a 0xFFFFFFFF
  size sentinel, and the frame rate), followed by size-delimited chunks
  with 8-byte preambles.  This header unit walks bounded chunks until the
  first RoQ_QUAD_INFO (0x1001), whose 8-byte payload carries dimensions.
  Sound chunks are valid before QUAD_INFO; traversal after the first INFO
  chunk is deferred to a depth unit.

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 64×64 @ 15fps
  sample (ffmpeg `-f lavfi testsrc=64x64:1:15`).
  Gallery status: **net-new** — no RoQ entry exists at formats.kaitai.io;
  this is the first video format in the corpus and exercises a bounded
  preamble/payload walk.

seq:
  - id: signature
    contents: [0x84, 0x10]
    doc: Magic number 0x1084 (little-endian).
  - id: file_size_sentinel
    contents: [0xff, 0xff, 0xff, 0xff]
    doc: Fixed 0xFFFFFFFF sentinel required by the RoQ container header.
  - id: frame_rate
    type: u2
    doc: Video frame rate in frames per second.
  - id: chunks_through_info
    type: chunk
    repeat: until
    repeat-until: _.chunk_id == 0x1001
    doc: Bounded chunks through the first RoQ_QUAD_INFO record.

types:
  chunk:
    seq:
      - id: chunk_id
        type: u2
        doc: |
          Chunk type.  0x1001 = quad_info (dimensions), 0x1002 = codebook,
          0x1011 = video data, 0x1020 = mono sound, 0x1021 = stereo sound.
      - id: len_body
        type: u4
        doc: Chunk data size in bytes (excluding this 8-byte preamble).
      - id: chunk_arg
        type: u2
        doc: Chunk argument (meaning depends on chunk type).
      - id: body
        size: len_body
        type: chunk_payload
        doc: Bounded chunk payload.

  chunk_payload:
    seq:
      - id: quad_info
        type: quad_info
        if: _parent.chunk_id == 0x1001
        doc: Parsed RoQ_QUAD_INFO payload.
      - id: uninterpreted
        size-eos: true
        if: _parent.chunk_id != 0x1001
        doc: Payload for chunk types outside this header unit's scope.

  quad_info:
    doc: |
      RoQ_QUAD_INFO chunk data — frame dimensions plus two historically
      unused words whose semantics are intentionally not asserted here.
    seq:
      - id: width
        type: u2
        doc: Frame width in pixels.
      - id: height
        type: u2
        doc: Frame height in pixels.
      - id: unknown_1
        type: u2
        doc: First historically unused QUAD_INFO word.
      - id: unknown_2
        type: u2
        doc: Second historically unused QUAD_INFO word.

instances:
  quad_info:
    value: chunks_through_info.last.body.quad_info
    doc: |
      First validated QUAD_INFO payload found by the bounded chunk walk.
      Exposes width and height; frame rate lives in the file header.

  codec_label:
    value: '"roq"'
    doc: |
      ffprobe codec name — RoQ containers always carry id RoQ video.
      There is only one video codec for this format, so the label
      is constant rather than derived from a header field.

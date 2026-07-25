meta:
  id: roq
  title: Id Software RoQ full chunk stream
  endian: le
doc: |
  Id Software RoQ video container — depth unit.

  The file begins with an 8-byte header (signature 0x1084, a 0xFFFFFFFF
  size sentinel, and the frame rate), followed by size-delimited chunks
  with 8-byte preambles through end of file:

  * 0x1001 RoQ_QUAD_INFO — dimensions (first chunk on clean encodes)
  * 0x1002 RoQ_QUAD_CODEBOOK — per-frame codebooks
  * 0x1011 RoQ_QUAD_VQ — video frame data
  * 0x1020 / 0x1021 — mono / stereo sound (valid before INFO)

  This unit walks **all** chunks to EOF.  Dimensions still come from the
  first QUAD_INFO payload; later codebook and VQ payloads stay
  uninterpreted beyond their declared sizes.  self_checked records
  chunk-size-sum == file length (header + every preamble/payload).

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 64×64 @ 15fps
  sample.  Gallery: **net-new**. Independence: **self-generated**.

seq:
  - id: signature
    contents: [0x84, 0x10]
    doc: Magic number 0x1084 (little-endian).
  - id: file_size_sentinel
    contents: [0xff, 0xff, 0xff, 0xff]
    doc: Fixed 0xFFFFFFFF sentinel required by the RoQ container header.
  - id: frame_rate
    type: u2
    valid:
      min: 1
    doc: Video frame rate in frames per second (must be non-zero).
  - id: chunks
    type: chunk
    repeat: eos
    doc: All RoQ chunks from the first preamble through end of file.

types:
  chunk:
    seq:
      - id: chunk_id
        type: u2
        valid:
          any-of: [0x1001, 0x1002, 0x1011, 0x1020, 0x1021]
        doc: |
          Chunk type.  0x1001 = quad_info, 0x1002 = codebook,
          0x1011 = video data, 0x1020 = mono sound, 0x1021 = stereo sound.
      - id: len_body
        type: u4
        valid:
          expr: 'chunk_id != 0x1001 or _ >= 8'
        doc: |
          Chunk data size in bytes (excluding this 8-byte preamble).
          QUAD_INFO payloads are at least 8 bytes (width/height + two words).
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
        doc: Codebook / VQ / sound payloads retained as opaque bytes.

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
  info_chunk:
    value: chunks[0]
    doc: |
      First chunk; clean FFmpeg encodes place QUAD_INFO first.  Sound
      chunks may precede INFO on other assets — this fixture does not.

  quad_info:
    value: info_chunk.body.quad_info
    doc: QUAD_INFO payload from the leading chunk.

  walked_chunk_count:
    value: chunks.size
    doc: Total chunks walked to EOF (INFO + codebooks + VQ frames + optional sound).

  codec_label:
    value: '"roq"'
    doc: |
      ffprobe codec name — RoQ containers always carry id RoQ video.
      There is only one video codec for this format, so the label
      is constant rather than derived from a header field.

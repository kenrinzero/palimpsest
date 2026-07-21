meta:
  id: aiff
  title: Audio Interchange File Format (AIFF) common header
  endian: be
doc: |
  Uncompressed Audio Interchange File Format (AIFF) container header.

  The outer IFF FORM is identified as AIFF and bounds a sequence of
  size-delimited chunks.  This breadth unit walks through the first COMM
  chunk, including even-byte chunk padding, and exposes its channel count,
  sample-frame count, and sample size.  Parsing beyond the first COMM and
  decoding the 80-bit extended sample rate are deferred to depth work.

  Proven against ffprobe 6.1.1-3ubuntu5 on a deterministic, self-generated
  80-frame, 8 kHz mono pcm_s16be sample.  Independence regime:
  self-generated (independent of this spec, but not of FFmpeg).  Gallery
  status: **net-new** — the live Kaitai gallery has no AIFF entry.

seq:
  - id: form_tag
    contents: 'FORM'
    doc: IFF container identifier.
  - id: form_size
    type: u4
    doc: Bytes after this field, including the four-byte form type.
  - id: form_type
    contents: 'AIFF'
    doc: Uncompressed AIFF form type; AIFC is intentionally rejected.
  - id: chunks
    size: form_size - 4
    type: chunk_area
    doc: FORM-size-bounded chunk area.

types:
  chunk_area:
    seq:
      - id: chunks_through_common
        type: chunk
        repeat: until
        repeat-until: _.chunk_id == "COMM"
        doc: Size-bounded chunks through the first Common Chunk.

  chunk:
    seq:
      - id: chunk_id
        type: str
        size: 4
        encoding: ASCII
        doc: Four-character IFF chunk identifier.
      - id: len_body
        type: u4
        doc: Chunk payload size, excluding this eight-byte header and padding.
      - id: body
        size: len_body
        type: chunk_body
        doc: Payload bounded by the chunk's declared size.
      - id: pad
        size: len_body % 2
        doc: IFF pad byte present after an odd-sized payload.

  chunk_body:
    seq:
      - id: common
        type: common_chunk
        if: _parent.chunk_id == "COMM"
      - id: uninterpreted
        size-eos: true
        if: _parent.chunk_id != "COMM"
        doc: Chunks preceding COMM are retained but not interpreted.

  common_chunk:
    seq:
      - id: num_channels
        type: u2
        doc: Number of interleaved audio channels.
      - id: num_sample_frames
        type: u4
        doc: Number of sample frames in the sound data.
      - id: sample_size
        type: u2
        doc: Number of bits in each sample point.
      - id: sample_rate_extended
        size: 10
        doc: Sample rate encoded as an IEEE 80-bit extended floating-point value.

instances:
  common:
    value: chunks.chunks_through_common.last.body.common
    doc: First Common Chunk found by the bounded chunk walk.

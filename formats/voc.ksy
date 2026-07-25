meta:
  id: voc
  title: Creative Voice (VOC) full block stream
  endian: le
doc: |
  VOC (Creative Voice) audio container — depth unit.

  Layout:

  * 26-byte header (magic, DOS EOF, data_offset, version, id_code)
  * optional padding bytes up to `data_offset`
  * size-delimited data blocks until a type-0 terminator byte:
      type u1; if type != 0: 24-bit LE size + payload

  Block types used by the self-generated fixture:

  * type 9 — extended format (v1.20+): sample rate, bits, channels, codec
  * type 2 — continuation (raw sample bytes, same params as prior type 9)
  * type 0 — terminator (single byte, no size/payload)

  This unit walks the full block stream.  Oracle fields still come from
  the first type-9 block (required for the fixture).  Legacy type-1
  packing remains uninterpreted if encountered.

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 11025 Hz
  mono pcm_s16le sample.  Gallery: gallery-improving
  (`creative_voice_file` exists at formats.kaitai.io).

seq:
  - id: magic
    contents: 'Creative Voice File'
    doc: Literal "Creative Voice File" without NUL terminator.
  - id: eof_byte
    contents: [0x1a]
    doc: DOS EOF / terminator marker.
  - id: data_offset
    type: u2
    valid:
      min: 26
    doc: Byte offset of the first data block from the start of the file.
  - id: version_minor
    type: u1
    doc: Numeric minor version component.
  - id: version_major
    type: u1
    doc: Numeric major version component.
  - id: id_code
    type: u2
    valid: '(0x1234 + (0xffff - ((version_major << 8) | version_minor))) & 0xffff'
    doc: Complementary code (~version + 0x1234) used to validate the header.
  - id: header_pad
    size: data_offset - 26
    doc: Bytes between the fixed 26-byte header and the first data block.
  - id: blocks
    type: block
    repeat: until
    repeat-until: _.block_type == 0
    doc: Data blocks through the type-0 terminator.

types:
  block:
    seq:
      - id: block_type
        type: u1
        doc: |
          Block type.  0 = terminator, 1 = legacy sound data, 2 =
          continuation, 9 = extended format (v1.20+).
      - id: size_b0
        type: u1
        if: block_type != 0
      - id: size_b1
        type: u1
        if: block_type != 0
      - id: size_b2
        type: u1
        if: block_type != 0
      - id: body
        size: len_body
        type: block_body
        if: block_type != 0
        doc: Payload for non-terminator blocks.
    instances:
      len_body:
        value: 'block_type == 0 ? 0 : (size_b0 | (size_b1 << 8) | (size_b2 << 16))'
        doc: 24-bit little-endian payload size (0 for the terminator).

  block_body:
    seq:
      - id: type9
        type: block_type9
        if: _parent.block_type == 9
      - id: uninterpreted
        size-eos: true
        if: _parent.block_type != 9
        doc: Continuation / legacy payloads retained as opaque bytes.

  block_type9:
    doc: |
      Extended data block (VOC v1.20+).
      Carries explicit sample rate / bits / channels / codec instead
      of the legacy frequency-divisor + codec byte scheme.
    seq:
      - id: sample_rate
        type: u4
        valid:
          min: 1
        doc: Sample rate in Hz.
      - id: bits_per_sample
        type: u1
        doc: Bits per sample (8, 16, ...).
      - id: channels
        type: u1
        valid:
          min: 1
        doc: Number of interleaved audio channels.
      - id: codec
        type: u2
        doc: |
          Codec identifier.
          0x0000 = 8-bit unsigned PCM, 0x0004 = 16-bit signed PCM,
          0x0006 = A-law, 0x0007 = μ-law.
      - id: reserved
        size: 4
        doc: Reserved bytes (zero in the generated fixture).
      - id: sample_data
        size-eos: true
        doc: PCM sample frames for this extended block.

instances:
  first_block:
    value: blocks[0]
    doc: First data block (type 9 for the self-generated fixture).

  first_type9:
    value: first_block.body.type9
    doc: Extended-format payload of the first block.

  first_block_sample_rate:
    value: first_type9.sample_rate
    doc: Sample rate from the first type-9 block.

  first_block_channels:
    value: first_type9.channels
    doc: Channel count from the first type-9 block.

  walked_block_count:
    value: blocks.size
    doc: Number of blocks walked including the type-0 terminator.

  codec_label:
    value: >
      first_type9.codec == 0 ? "pcm_u8" :
      first_type9.codec == 4 ? "pcm_s16le" :
      first_type9.codec == 6 ? "pcm_alaw" :
      first_type9.codec == 7 ? "pcm_mulaw" :
      "unknown"
    doc: |
      ffprobe-compatible codec name derived from the type-9 codec field.
      Covers the four codecs ffmpeg 6.1.1 encodes when writing VOC.

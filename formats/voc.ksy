meta:
  id: voc
  title: Creative Voice (VOC) audio file header
  endian: le
doc: |
  VOC (Creative Voice) audio container header.

  The file begins with a 26-byte header followed by data blocks.  This
  header unit requires and exposes a type-9 first block (extended format,
  v1.20+), whose payload has explicit sample rate, channels, and codec
  fields.  Legacy type-1 decoding and full block traversal are deferred to
  a depth unit.

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 11025 Hz
  mono pcm_s16le sample (ffmpeg `-f lavfi sine:440:1 -ar 11025 -ac 1`).
  Gallery status: gallery-improving (a `creative_voice_file` entry exists
  at formats.kaitai.io — this one adds the conformance gate).

seq:
  - id: magic
    contents: 'Creative Voice File'
    doc: Literal "Creative Voice File" without NUL terminator.
  - id: eof_byte
    contents: [0x1a]
    doc: DOS EOF / terminator marker.
  - id: data_offset
    type: u2
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

types:
  type9_block:
    seq:
      - id: block_type
        type: u1
        valid: 9
        doc: Extended-format block type (9).
      - id: block_size_b0
        type: u1
      - id: block_size_b1
        type: u1
      - id: block_size_b2
        type: u1
      - id: body
        size: len_body
        type: block_type9
        doc: Bounded type-9 payload.
    instances:
      len_body:
        value: block_size_b0 | (block_size_b1 << 8) | (block_size_b2 << 16)
        doc: 24-bit little-endian block payload size (excludes the 4-byte header).

  block_type9:
    doc: |
      Extended data block (VOC v1.20+).
      Carries explicit sample rate / bits / channels / codec instead
      of the legacy frequency-divisor + codec byte scheme.
    seq:
      - id: sample_rate
        type: u4
        doc: Sample rate in Hz.
      - id: bits_per_sample
        type: u1
        doc: Bits per sample (8, 16, ...).
      - id: channels
        type: u1
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

instances:
  first_block:
    pos: data_offset
    type: type9_block
    doc: The required type-9 first data block.

  first_block_sample_rate:
    value: first_block.body.sample_rate
    doc: Sample rate from the first data block.

  first_block_channels:
    value: first_block.body.channels
    doc: Channel count from the first data block.

  codec_label:
    value: >
      first_block.body.codec == 0 ? "pcm_u8" :
      first_block.body.codec == 4 ? "pcm_s16le" :
      first_block.body.codec == 6 ? "pcm_alaw" :
      first_block.body.codec == 7 ? "pcm_mulaw" :
      "unknown"
    doc: |
      ffprobe-compatible codec name derived from the type-9 codec field.
      Covers the four codecs ffmpeg 6.1.1 encodes when writing VOC.

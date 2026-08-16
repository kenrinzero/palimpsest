meta:
  id: wsaud
  title: Westwood Studios AUD header and chunk stream
  endian: le
doc: |
  Westwood Studios AUD audio container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/westwood_aud.c and westwood_audenc.c):

  * 12-byte header: sample rate, compressed payload size, uncompressed
    size, flags, codec
  * 8-byte chunk preambles (payload size, uncompressed size, 0x0000DEAF)
    through EOF

  Flags: bit 0 stereo, bit 1 marks 16-bit source (set by the ADPCM
  muxer); the top 6 bits are reserved 0.  Codec 99 is IMA ADPCM WS;
  codec 1 is Westwood SND1 (not produced by the muxer).

  Payload bytes stay uninterpreted — this unit specs the container,
  not ADPCM math.

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 22050 Hz
  mono adpcm_ima_ws sample.  Gallery: **net-new**.
  Independence: **self-generated**.

seq:
  - id: sample_rate
    type: u2
    valid:
      min: 8000
      max: 48000
    doc: Sample rate in Hz (probe accepts 8000–48000).
  - id: payload_size
    type: u4
    valid:
      min: 8
    doc: |
      Size in bytes of every chunk (preamble + payload) after the
      12-byte header.  Equals file length minus 12.
  - id: uncompressed_size
    type: u4
    doc: Declared uncompressed PCM byte count (muxer writes size*4).
  - id: flags
    type: u1
    valid:
      expr: '(_ & 252) == 0'
    doc: Bit 0 = stereo, bit 1 = 16-bit source; bits 2–7 reserved 0.
  - id: codec
    type: u1
    valid:
      any-of: [1, 99]
    doc: 1 = Westwood SND1, 99 = IMA ADPCM WS.
  - id: chunks
    type: chunk
    repeat: eos
    doc: AUD chunks through end of file.

types:
  chunk:
    seq:
      - id: len_body
        type: u2
        valid:
          min: 1
        doc: Compressed payload size (excludes this 8-byte preamble).
      - id: uncompressed_size
        type: u2
        doc: Uncompressed size for this chunk (SND1 output size; ADPCM uses 4×).
      - id: signature
        type: u4
        valid:
          eq: 0xdeaf
        doc: Chunk signature 0x0000DEAF (little-endian AF DE 00 00).
      - id: body
        size: len_body
        doc: Uninterpreted ADPCM (or SND1) payload.

instances:
  channels:
    value: '(flags & 1) + 1'
    doc: Channel count from flags bit 0 (1 = mono, 2 = stereo).
  walked_chunk_count:
    value: chunks.size
    doc: Number of AUD chunks walked to EOF.
  codec_label:
    value: >
      codec == 99 ? "adpcm_ima_ws" :
      codec == 1 ? "westwood_snd1" :
      "unknown"
    doc: ffprobe codec_name derived from the header codec byte.

meta:
  id: xa
  title: Maxis XA header
  endian: le
doc: |
  Maxis XA audio container — header unit.

  Not CRI ADX.  FFmpeg codec is adpcm_ea_maxis_xa.

  Layout (FFmpeg 6.1.1 libavformat/xa.c):

  * "XA\\0\\0", "XAI\\0", or "XAJ\\0"
  * u32le output size, u16le tag, u16le channels
  * u32le sample rate, u32le average byte rate
  * u16le block align, u16le bits per sample
  * bit_rate = 15 × channels × 8 × rate / 28

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `maxis-xa/SC2KBUG.XA` (adpcm_ea_maxis_xa 22050 Hz/2 ch,
  189000 bit_rate).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: magic
    contents: XA
    doc: XA signature prefix.
  - id: variant
    type: u1
    valid:
      any-of: [0, 0x49, 0x4a]
    doc: 0 / 'I' / 'J' — XA00, XAI0, or XAJ0.
  - id: nul
    contents: [0]
    doc: Trailing NUL of the four-byte tag.
  - id: out_size
    type: u4
    doc: Declared decoded output size (may exceed the file).
  - id: tag
    type: u2
    doc: Unused format tag.
  - id: channels
    type: u2
    valid:
      min: 1
      max: 8
    doc: Channel count.
  - id: sample_rate
    type: u4
    valid:
      min: 1
    doc: Sample rate in Hz.
  - id: avg_byte_rate
    type: u4
    doc: Average byte rate (unused here).
  - id: block_align
    type: u2
    doc: Block align (unused here).
  - id: bits_per_sample
    type: u2
    valid:
      min: 4
      max: 32
    doc: Bits per sample.  Probe range check only.
  - id: rest
    size-eos: true
    doc: ADPCM blocks (uninterpreted).

instances:
  bit_rate:
    value: 15 * channels * 8 * sample_rate / 28
    doc: ffprobe bit_rate (15 × ch × 8 × rate / 28).
  codec_label:
    value: '"adpcm_ea_maxis_xa"'
    doc: ffprobe codec_name.  Maxis XA is not CRI ADX.

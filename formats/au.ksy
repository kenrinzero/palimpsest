meta:
  id: au
  title: Sun/NeXT AU audio file header
  endian: be
doc: |
  AU (Sun/NeXT) audio container header.

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 8 kHz mono
  pcm_s16be sample.  The spec exposes the mandatory header fields
  (magic, data_offset, data_size, encoding, sample_rate, channels)
  plus a derived `codec_label` instance that maps the encoding integer
  to ffprobe's `codec_name` string.

  Malformed-input hardening (2026-07-25): `data_offset` must be at least
  24 (end of the fixed header); `sample_rate` and `channels` must be
  non-zero.  `redteam/au_short_offset.bin` is proven red by selftest.

  Gallery status: gallery-improving — an `au` entry already exists at
  formats.kaitai.io; this one adds the differential-gate oracle.

seq:
  - id: magic
    contents: '.snd'
  - id: data_offset
    type: u4
    valid:
      min: 24
    doc: Byte offset to start of audio data (minimum 24 = end of fixed header).
  - id: data_size
    type: u4
    doc: Size of audio data in bytes, or 0xFFFFFFFF for unknown.
  - id: encoding
    type: u4
    doc: |
      Audio encoding code.
      1 = μ-law, 2 = 8-bit linear PCM, 3 = 16-bit linear PCM,
      4 = 24-bit linear PCM, 5 = 32-bit linear PCM,
      6 = 32-bit float, 7 = 64-bit float, 23/25/26/"7262" = G.726,
      24 = G.722, 27 = A-law.
  - id: sample_rate
    type: u4
    valid:
      min: 1
    doc: Samples per second (must be non-zero).
  - id: channels
    type: u4
    valid:
      min: 1
    doc: Number of interleaved audio channels (must be non-zero).
instances:
  codec_label:
    value: >
      encoding == 1 ? "pcm_mulaw" :
      encoding == 2 ? "pcm_s8" :
      encoding == 3 ? "pcm_s16be" :
      encoding == 4 ? "pcm_s24be" :
      encoding == 5 ? "pcm_s32be" :
      encoding == 6 ? "pcm_f32be" :
      encoding == 7 ? "pcm_f64be" :
      encoding == 23 ? "adpcm_g726le" :
      encoding == 24 ? "adpcm_g722" :
      encoding == 25 ? "adpcm_g726le" :
      encoding == 26 ? "adpcm_g726le" :
      encoding == 27 ? "pcm_alaw" :
      encoding == 0x37323632 ? "adpcm_g726le" :
      "unknown"
    doc: |
      ffprobe-compatible codec name derived from the encoding integer.
      The exhaustive mapping covers every encoding FFmpeg 6.1.1
      recognizes for the AU container.

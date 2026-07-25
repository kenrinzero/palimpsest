meta:
  id: aiff
  title: Audio Interchange File Format (AIFF) header depth
  endian: be
doc: |
  Uncompressed Audio Interchange File Format (AIFF) — depth unit.

  The outer IFF FORM is identified as AIFF (AIFC rejected) and bounds a
  sequence of size-delimited chunks with even-byte padding.  This unit:

  * walks chunks through the first COMM (Common) chunk
  * continues the walk through the first SSND (Sound Data) chunk
  * decodes the COMM sample rate from IEEE 80-bit extended floating
    point into an integer Hz value for positive, finite, normalized
    rates whose unbiased exponent is in 0..63 (covers standard audio
    rates including the self-generated 8000 Hz fixture)

  Extended-float decode (Apple SANE / IEEE 754 extended layout):

  * bits 0–14 of the first u2: biased exponent (bias 16383)
  * bit 15: sign
  * following u8: significand with explicit integer bit
  * integer Hz = mantissa >> (63 - (exp - 16383)) when the conditions
    above hold

  FORM size is the IFF byte count after the size field; for a single
  top-level FORM file, `form_size + 8` equals the file length
  (recorded under self_checked as chunk-size-sum == file length).

  Malformed-input hardening (2026-07-25): `form_size` must be large
  enough to hold form type + a full COMM (26 bytes) + a minimal SSND
  header (16 bytes) ⇒ minimum 46.  COMM payloads must be exactly 18
  bytes (classic AIFF); SSND payloads must be at least 8 bytes
  (offset + block_size).  Undersized FORM fixtures in `redteam/` are
  proven red by `./check.sh --selftest`.

  Proven against ffprobe 6.1.1-3ubuntu5 on the deterministic
  self-generated 80-frame, 8 kHz mono pcm_s16be sample.  Independence:
  self-generated.  Gallery: **net-new**.

seq:
  - id: form_tag
    contents: 'FORM'
    doc: IFF container identifier.
  - id: form_size
    type: u4
    valid:
      min: 46
    doc: |
      Bytes after this field, including the four-byte form type.
      Minimum 46 = AIFF(4) + COMM(8+18) + SSND(8+8) so this depth unit
      can complete both chunk walks.  Undersized values fail validation
      before any chunk parse (see redteam/aiff_undersized_form.bin).
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
      - id: chunks_through_sound
        type: chunk
        repeat: until
        repeat-until: _.chunk_id == "SSND"
        doc: Continuing walk through the first Sound Data Chunk.

  chunk:
    seq:
      - id: chunk_id
        type: str
        size: 4
        encoding: ASCII
        doc: Four-character IFF chunk identifier.
      - id: len_body
        type: u4
        valid:
          expr: |
            (chunk_id == "COMM" and _ == 18) or
            (chunk_id == "SSND" and _ >= 8) or
            (chunk_id != "COMM" and chunk_id != "SSND")
        doc: |
          Chunk payload size, excluding this eight-byte header and padding.
          Classic AIFF COMM is always 18 bytes; SSND must cover offset and
          block_size (at least 8).  Other chunks are unconstrained here.
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
      - id: sound
        type: sound_data_chunk
        if: _parent.chunk_id == "SSND"
      - id: uninterpreted
        size-eos: true
        if: (_parent.chunk_id != "COMM") and (_parent.chunk_id != "SSND")
        doc: Chunks outside COMM/SSND are retained but not interpreted.

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
        type: extended80
        doc: Sample rate as IEEE 80-bit extended floating-point.

  sound_data_chunk:
    doc: |
      SSND chunk: offset and block-size leading words, then the PCM
      sample frames.  Offset/block-size are usually zero for simple
      files; sample bytes remain uninterpreted beyond their declared
      length.
    seq:
      - id: offset
        type: u4
        doc: Bytes to skip before the first sample frame (usually 0).
      - id: block_size
        type: u4
        doc: Block-alignment size for the sound data (usually 0).
      - id: sound_data
        size-eos: true
        doc: Raw PCM sample frames (AIFF big-endian integer PCM).

  extended80:
    doc: |
      IEEE 754 80-bit extended (Apple SANE) floating-point value used
      by AIFF for sample rate.  Only the positive integer-Hz decode path
      is exposed for differential checking.
    seq:
      - id: sign_exp
        type: u2
        doc: Sign bit (MSB) plus 15-bit biased exponent.
      - id: mantissa
        type: u8
        doc: 64-bit significand with explicit integer bit in the MSB.
    instances:
      sign:
        value: sign_exp >> 15
        doc: 0 = positive, 1 = negative.
      raw_exp:
        value: sign_exp & 0x7fff
        doc: Biased exponent field (bias 16383; 0 and 0x7FFF are special).
      unbiased_exp:
        value: raw_exp - 16383
        doc: Unbiased power-of-two exponent for normal numbers.
      as_hz:
        value: mantissa >> (63 - unbiased_exp)
        if: (sign == 0) and (raw_exp != 0) and (raw_exp != 0x7fff) and (unbiased_exp >= 0) and (unbiased_exp <= 63)
        doc: |
          Integer sample rate in Hz for positive finite normals whose
          unbiased exponent fits a right-shift decode (0..63).  Standard
          audio rates (8000, 11025, 22050, 44100, 48000, …) land here.

instances:
  common:
    value: chunks.chunks_through_common.last.body.common
    doc: First Common Chunk found by the bounded chunk walk.

  sound:
    value: chunks.chunks_through_sound.last.body.sound
    doc: First Sound Data Chunk found after COMM.

  sample_rate:
    value: common.sample_rate_extended.as_hz
    doc: Decoded integer sample rate (Hz) for differential vs ffprobe.

  codec_label:
    value: |
      common.sample_size == 16 ? "pcm_s16be" : (
        common.sample_size == 8 ? "pcm_s8" : (
          common.sample_size == 24 ? "pcm_s24be" : (
            common.sample_size == 32 ? "pcm_s32be" : "unknown"
          )
        )
      )
    doc: |
      Uncompressed AIFF PCM is big-endian; map common sample sizes to
      ffprobe codec_name values.

  form_total_size:
    value: form_size + 8
    doc: |
      Declared top-level FORM length including the 8-byte FORM header
      (tag + size).  Equals the file size for a single-FORM AIFF file.

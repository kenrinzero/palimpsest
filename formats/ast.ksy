meta:
  id: ast
  title: Nintendo AST header and BLCK stream
  endian: be
doc: |
  Nintendo AST (Audio Stream) container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/astdec.c and astenc.c):

  * 64-byte STRM header (size-minus-header, codec tag, bit depth,
    channels, loop flag, sample rate, sample count, loop points,
    first-block size)
  * BLCK chunks: fourcc, per-channel size, 24-byte pad, planar PCM
    (or AFC) payload of size × channels

  Codec tag 1 is PCM S16BE planar (this muxer); tag 0 is ADPCM AFC
  (demux-only).  Payload bytes stay uninterpreted.

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 32000 Hz
  stereo pcm_s16be_planar sample.  Gallery: **net-new**.
  Independence: **self-generated**.

seq:
  - id: magic
    contents: STRM
    doc: AST stream header tag.
  - id: size_minus_header
    type: u4
    valid:
      min: 32
    doc: File size minus the 64-byte STRM header.
  - id: codec_tag
    type: u2
    valid:
      any-of: [0, 1]
    doc: 0 = ADPCM AFC, 1 = PCM S16BE planar.
  - id: bit_depth
    type: u2
    valid:
      eq: 16
    doc: Bits per sample.  FFmpeg 6.1.1 accepts only 16.
  - id: channels
    type: u2
    valid:
      min: 1
      max: 256
    doc: Channel count.
  - id: loop_flag
    type: u2
    doc: 0 = no loop, 0xFFFF = loop (set by muxer when loopstart ≥ 0).
  - id: sample_rate
    type: u4
    valid:
      min: 1
    doc: Sample rate in Hz.
  - id: num_samples
    type: u4
    valid:
      min: 1
    doc: Declared PCM sample frames (ffprobe duration_ts).
  - id: loop_start
    type: u4
    doc: Loop start in samples (0 if unused).
  - id: loop_end
    type: u4
    doc: Loop end in samples (equals num_samples when unused).
  - id: first_block_size
    type: u4
    doc: Size of the first BLCK payload per channel.
  - id: header_pad
    size: 28
    doc: Remainder of the fixed 64-byte header.
  - id: blocks
    type: block
    repeat: eos
    doc: BLCK chunks through end of file.

types:
  block:
    seq:
      - id: tag
        contents: BLCK
        doc: Block tag.
      - id: len_per_channel
        type: u4
        valid:
          min: 1
        doc: Payload bytes per channel (not the full planar block).
      - id: padding
        size: 24
        doc: Unused 24-byte BLCK preamble.
      - id: body
        size: len_per_channel * _root.channels
        doc: Uninterpreted planar PCM or AFC payload.

instances:
  walked_block_count:
    value: blocks.size
    doc: Number of BLCK chunks walked to EOF.
  codec_label:
    value: >
      codec_tag == 1 ? "pcm_s16be_planar" :
      codec_tag == 0 ? "adpcm_afc" :
      "unknown"
    doc: ffprobe codec_name derived from the STRM codec tag.

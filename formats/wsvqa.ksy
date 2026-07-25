meta:
  id: wsvqa
  title: Westwood Studios VQA header through FINF
  endian: le
doc: |
  Westwood Studios VQA (Vector Quantized Animation) — depth unit.

  IFF-style container: big-endian FORM size, form type WVQA, then a
  sequence of size-delimited chunks (tag + u4be size + payload + pad).

  This unit:

  * parses the leading VQHD chunk (fixed 42-byte Westwood VQAHeader)
  * continues the IFF walk through LINF/CINF/… until FINF
  * treats FINF as a table of `num_frames` little-endian frame offsets
    (entry count = payload_size / 4)

  FATE `small-cut-v3.vqa` is a truncated partial; the FORM size field
  reflects the original full asset and is **not** used to bound the
  post-VQHD walk.  Chunks after FINF (SND2/VQFR/…) remain uninterpreted.

  Audio codec label follows the Westwood ADPCM convention used by
  ffprobe for SND2-bearing V3 samples (`adpcm_ima_ws`).

  Proven against ffprobe 6.1.1-3ubuntu5 (140×110 @ 15 fps, 96 frames,
  ws_vqa + adpcm_ima_ws 22050 Hz/1 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: form_tag
    contents: 'FORM'
    doc: IFF container tag.
  - id: form_size
    type: u4be
    doc: |
      Size of everything after this field (big-endian IFF convention).
      May exceed the on-disk length for truncated FATE partials.
  - id: form_type
    contents: 'WVQA'
    doc: IFF form type identifier.
  - id: chunks_through_finf
    type: iff_chunk
    repeat: until
    repeat-until: _.chunk_id == "FINF"
    doc: IFF chunks from VQHD through the frame-offset table (FINF).

types:
  iff_chunk:
    seq:
      - id: chunk_id
        type: str
        size: 4
        encoding: ASCII
        doc: Four-character IFF chunk identifier.
      - id: len_body
        type: u4be
        doc: Payload size after this field (big-endian).
      - id: body
        size: len_body
        type: chunk_body
        doc: Payload bounded by the chunk's declared size.
      - id: pad
        size: len_body % 2
        doc: IFF pad byte after an odd-sized payload.

  chunk_body:
    seq:
      - id: vqhd
        type: vqhd_chunk
        if: _parent.chunk_id == "VQHD"
      - id: finf
        type: finf_chunk
        if: _parent.chunk_id == "FINF"
      - id: uninterpreted
        size-eos: true
        if: (_parent.chunk_id != "VQHD") and (_parent.chunk_id != "FINF")
        doc: LINF/CINF and other pre-FINF chunks retained but not interpreted.

  vqhd_chunk:
    doc: Fixed 42-byte Westwood VQAHeader (VQHD payload).
    seq:
      - id: version
        type: u2
        doc: VQA format version (1, 2, or 3).
      - id: vqa_flags
        type: u2
        doc: Flags (bit 0 = has sound, etc.).
      - id: num_frames
        type: u2
        doc: Number of frames.
      - id: width
        type: u2
        doc: Frame width in pixels.
      - id: height
        type: u2
        doc: Frame height in pixels.
      - id: block_w
        type: u1
        doc: Macroblock width (typically 4).
      - id: block_h
        type: u1
        doc: Macroblock height (typically 2).
      - id: frame_rate
        type: u1
        doc: Frame rate in fps.
      - id: group_size
        type: u1
        doc: Frames per codebook group.
      - id: num_1_colors
        type: u2
        doc: Number of one-color entries.
      - id: codebook_entries
        type: u2
        doc: Number of codebook entries.
      - id: x_pos
        type: u2
        doc: Horizontal playback position (0xFFFF = center).
      - id: y_pos
        type: u2
        doc: Vertical playback position (0xFFFF = center).
      - id: max_frame_size
        type: u2
        doc: Size of the largest frame.
      - id: sample_rate
        type: u2
        doc: Primary audio sample rate in Hz.
      - id: channels
        type: u1
        doc: Number of primary audio channels.
      - id: bits_per_sample
        type: u1
        doc: Primary audio sample size in bits.
      - id: alt_sample_rate
        type: u2
        doc: Alternate audio stream sample rate in Hz.
      - id: alt_channels
        type: u1
        doc: Number of alternate audio channels.
      - id: alt_bits_per_sample
        type: u1
        doc: Alternate audio sample size in bits.
      - id: future_use
        type: u2
        repeat: expr
        repeat-expr: 5
        doc: Five reserved words completing the fixed 42-byte payload.

  finf_chunk:
    doc: |
      FINF frame information table — one little-endian u4 file offset
      per frame.  Entry count must equal VQHD.num_frames.
    seq:
      - id: frame_offsets
        type: u4
        repeat: eos
        doc: Absolute offsets of VQFR (and related) frame payloads.

    instances:
      entry_count:
        value: frame_offsets.size
        doc: Number of frame offset entries (= payload_size / 4).

instances:
  vqhd:
    value: chunks_through_finf.first.body.vqhd
    doc: Leading VQHD header chunk (required first chunk of WVQA).

  finf:
    value: chunks_through_finf.last.body.finf
    doc: FINF table reached by the bounded IFF walk.

  version:
    value: vqhd.version
  num_frames:
    value: vqhd.num_frames
  width:
    value: vqhd.width
  height:
    value: vqhd.height
  frame_rate:
    value: vqhd.frame_rate
  sample_rate:
    value: vqhd.sample_rate
  channels:
    value: vqhd.channels
  bits_per_sample:
    value: vqhd.bits_per_sample
  codebook_entries:
    value: vqhd.codebook_entries
  finf_entry_count:
    value: finf.entry_count
    doc: Walked FINF entry count; equals num_frames by format contract.

  codec_label:
    value: '"ws_vqa"'
    doc: ffprobe video codec name for Westwood VQA.

  audio_codec_label:
    value: 'sample_rate != 0 ? "adpcm_ima_ws" : "none"'
    doc: |
      ffprobe audio codec for V3 samples with a non-zero VQHD sample
      rate (SND2 / IMA ADPCM Westwood).  Absent when sample_rate is 0.

meta:
  id: argo_asf
  title: Argonaut Games ASF header
  endian: le
doc: |
  Argonaut Games ASF audio container (Croc, Croc 2, FX Fighter) —
  header unit.  Not Microsoft ASF.

  Layout (FFmpeg 6.1.1 libavformat/argo_asf.c):

  * 24-byte file header (ASF\\0, version, chunk count, first-chunk
    offset, 8-byte name)
  * optional pad to chunk_offset
  * 20-byte chunk header (block count, 32 samples/block, rate, flags)
  * ADPCM-ARGO blocks (uninterpreted)

  Flags: bit 0 = 16-bit, bit 1 = stereo, bits 2–3 always set.
  v1.1 files store 44100 in the chunk but play at 22050.

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 22050 Hz
  mono v2.1 sample.  Gallery: **net-new**. Independence: **self-generated**.

seq:
  - id: magic
    contents: [0x41, 0x53, 0x46, 0x00]
    doc: Signature ASF followed by a NUL.
  - id: version_major
    type: u2
    doc: File major version (muxer default 2).
  - id: version_minor
    type: u2
    doc: File minor version (muxer default 1).
  - id: num_chunks
    type: u4
    valid:
      eq: 1
    doc: Standalone ASF has exactly one chunk (BRP may carry more).
  - id: chunk_offset
    type: u4
    valid:
      min: 24
    doc: Absolute offset of the first chunk header.
  - id: name
    size: 8
    doc: Embedded 8-byte title, NUL-padded.
  - id: header_pad
    size: chunk_offset - 24
    doc: Bytes between the file header and the first chunk.
  - id: chunk
    type: chunk_header
    doc: The single ASF chunk header.
  - id: blocks
    size-eos: true
    doc: Uninterpreted ADPCM-ARGO block stream.

types:
  chunk_header:
    seq:
      - id: num_blocks
        type: u4
        valid:
          min: 1
        doc: Number of ADPCM blocks in this chunk (ffprobe nb_frames).
      - id: num_samples
        type: u4
        valid:
          eq: 32
        doc: Samples per channel per block.  Always 32.
      - id: unk1
        type: u4
        doc: Unknown; muxer writes 0.
      - id: sample_rate
        type: u2
        valid:
          min: 1
        doc: Sample rate in Hz (ignored for v1.1; those play at 22050).
      - id: unk2
        type: u2
        doc: Unknown; muxer writes 0xFFFF.
      - id: flags
        type: u4
        valid:
          any-of: [0x0d, 0x0f]
        doc: |
          0x0D = 16-bit mono, 0x0F = 16-bit stereo.  Bits 2–3 always set;
          other bits reserved 0.

instances:
  sample_rate:
    value: 'version_major == 1 and version_minor == 1 ? 22050 : chunk.sample_rate'
    doc: Effective rate.  v1.1 FX Fighter files are 22050 despite the field.
  channels:
    value: '(chunk.flags & 2) != 0 ? 2 : 1'
    doc: Channel count from flags bit 1.
  num_frames:
    value: chunk.num_blocks
    doc: Block count; ffprobe reports this as nb_frames.
  duration_samples:
    value: chunk.num_blocks * chunk.num_samples
    doc: Total sample frames (blocks × 32).
  codec_label:
    value: '"adpcm_argo"'
    doc: |
      ffprobe codec_name.  Argonaut ASF always carries ADPCM-ARGO;
      the label is not a fourcc.

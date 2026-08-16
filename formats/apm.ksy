meta:
  id: apm
  title: Ubisoft Rayman 2 APM header
  endian: le
doc: |
  Ubisoft Rayman 2 APM audio container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/apm.c):

  * 20-byte WAVEFORMATEX-like prefix (codec 0x2000, channels, rate,
    byte rate, block align, 4-bit sample width, extradata size 80)
  * 80-byte tail: magic "vs12", file/data sizes, reserved state, "DATA"
  * IMA APM payload (uninterpreted)

  has_saved != 0 is a demuxer-rejected sample-history path and is
  refused here.  Predictor words stay uninterpreted.

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 22050 Hz
  mono sample.  Gallery: **net-new**. Independence: **self-generated**.

seq:
  - id: codec_tag
    type: u2
    valid:
      eq: 0x2000
    doc: APM codec tag (not a RIFF WAVE format tag in the usual sense).
  - id: channels
    type: u2
    valid:
      min: 1
      max: 2
    doc: Channel count.
  - id: sample_rate
    type: u4
    valid:
      min: 1
    doc: Sample rate in Hz.
  - id: byte_rate
    type: u4
    doc: |
      Declared byte rate.  The muxer writes sample_rate × channels × 2,
      which FFmpeg itself notes is the historical (wrong) value.
  - id: block_align
    type: u2
    doc: WAVEFORMATEX nBlockAlign (copied from the encoder).
  - id: bits_per_coded_sample
    type: u2
    valid:
      eq: 4
    doc: Coded bits per sample.  APM is 4-bit IMA.
  - id: extra_size
    type: u4
    valid:
      eq: 80
    doc: Size of the following vs12 tail.  Always 80.
  - id: extra
    type: extra_data
    doc: vs12 / DATA tail.
  - id: payload
    size-eos: true
    doc: Uninterpreted IMA APM bytes.

types:
  extra_data:
    seq:
      - id: magic
        contents: vs12
        doc: Extradata magic.
      - id: file_size
        type: u4
        valid:
          min: 100
        doc: Total file size including this header.
      - id: data_size
        type: u4
        valid:
          min: 1
        doc: Payload size (file size minus the 100-byte header).
      - id: unk1
        type: u4
        doc: Unknown; muxer writes 0xFFFFFFFF.
      - id: unk2
        type: u4
        doc: Unknown; muxer writes 0.
      - id: has_saved
        type: u4
        valid:
          eq: 0
        doc: Non-zero would prepend saved IMA samples; not handled here.
      - id: state_rest
        size: 24
        doc: Remaining IMA predictor/state words (uninterpreted).
      - id: unk3
        size: 28
        doc: Seven reserved u4 words.
      - id: data_tag
        contents: DATA
        doc: Payload marker.

instances:
  duration_samples:
    value: '(extra.data_size * 2) / channels'
    doc: |
      Demuxer duration: data_size × (8 / bits_per_coded_sample) /
      channels.  bits_per_coded_sample is fixed at 4.
  codec_label:
    value: '"adpcm_ima_apm"'
    doc: ffprobe codec_name.  APM always carries IMA APM.

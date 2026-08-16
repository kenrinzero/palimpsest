meta:
  id: kvag
  title: Simon and Schuster Interactive VAG header
  endian: le
doc: |
  Simon & Schuster Interactive VAG (KVAG) audio container — header unit.
  Not Sony VAG.

  Layout (FFmpeg 6.1.1 libavformat/kvag.c):

  * 14-byte header: "KVAG", data size, sample rate, stereo flag
  * IMA SSI payload (uninterpreted)

  stereo is 0 (mono) or 1 (stereo).  Duration is data_size × 2 /
  channels (4-bit IMA).

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 22050 Hz
  mono sample.  Gallery: **net-new**. Independence: **self-generated**.

seq:
  - id: magic
    contents: KVAG
    doc: Signature KVAG.
  - id: data_size
    type: u4
    valid:
      min: 1
    doc: Payload size in bytes (file length minus 14).
  - id: sample_rate
    type: u4
    valid:
      min: 1
    doc: Sample rate in Hz.
  - id: stereo
    type: u2
    valid:
      any-of: [0, 1]
    doc: 0 = mono, 1 = stereo.
  - id: payload
    size-eos: true
    doc: Uninterpreted ADPCM IMA SSI bytes.

instances:
  channels:
    value: stereo + 1
    doc: Channel count derived from the stereo flag.
  duration_samples:
    value: '(data_size * 2) / channels'
    doc: Demuxer duration (4-bit IMA, 2 samples per byte, per channel).
  codec_label:
    value: '"adpcm_ima_ssi"'
    doc: ffprobe codec_name.  KVAG always carries IMA SSI.

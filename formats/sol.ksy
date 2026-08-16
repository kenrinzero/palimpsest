meta:
  id: sol
  title: Sierra SOL header
  endian: le
doc: |
  Sierra SOL audio container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/sol.c):

  * u16le magic: 0x0B8D, 0x0C0D, or 0x0C8D
  * "SOL\\0", u16le sample rate, u8 type flags, u32le size
  * newer magics (not 0x0B8D) have a padding byte
  * type bit 0 = DPCM, bit 2 = 16-bit, bit 4 = stereo
  * 0x0B8D is always mono and never DPCM-new

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `sol/lsl7sample.sol` (sol_dpcm 22050 Hz/2 ch).
  Gallery: **net-new**.  Independence: **third-party**.

seq:
  - id: magic
    type: u2
    valid:
      any-of: [0x0b8d, 0x0c0d, 0x0c8d]
    doc: SOL magic.  Distinguishes old vs new DPCM variants.
  - id: tag
    contents: [0x53, 0x4f, 0x4c, 0x00]
    doc: Literal "SOL" plus NUL.
  - id: sample_rate
    type: u2
    valid:
      min: 1
    doc: Sample rate in Hz.
  - id: type_flags
    type: u1
    doc: |
      Bit 0 = DPCM, bit 2 = 16-bit PCM, bit 4 = stereo.
      0x0B8D ignores stereo and is never DPCM-new.
  - id: data_size
    type: u4
    doc: Declared payload size.
  - id: pad
    type: u1
    if: magic != 0x0b8d
    doc: Padding byte on 0x0C0D / 0x0C8D files.
  - id: rest
    size-eos: true
    doc: Audio payload (uninterpreted).

instances:
  is_dpcm:
    value: (type_flags & 1) != 0
    doc: Type bit 0.  Selects sol_dpcm over PCM.
  is_16bit:
    value: (type_flags & 4) != 0
    doc: Type bit 2.  Selects pcm_s16le when not DPCM.
  is_stereo:
    value: (type_flags & 16) != 0
    doc: Type bit 4.  Ignored for magic 0x0B8D.
  channels:
    value: 'magic == 0x0b8d or not is_stereo ? 1 : 2'
    doc: Channel count from magic and the stereo flag.
  codec_label:
    value: 'is_dpcm ? "sol_dpcm" : (magic == 0x0b8d ? "pcm_u8" : (is_16bit ? "pcm_s16le" : "pcm_u8"))'
    doc: ffprobe codec_name from magic + type flags.

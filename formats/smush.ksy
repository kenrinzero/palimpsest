meta:
  id: smush
  title: LucasArts Smush SANM header and FLHD
  endian: be
doc: |
  LucasArts Smush (SANM / .znm) container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/smush.c, version-1 SANM path):

  * SANM + u32be movie size (lies on this truncated FATE partial)
  * SHDR: u32be size, then mixed-endian body (u16le subversion,
    u32le frame count, pad, u16le width/height, pad, remainder)
  * FLHD: IFF-style subchunks until the first Wave
    (Wave = u32le rate + u32le channels; Bl16/ANNO skipped)
  * FRME / Wave / Bl16 packets after FLHD (uninterpreted)

  The ANIM/AHDR v0 path is not parsed here.  Video is always
  SANM; Wave audio is always ADPCM VIMA.  Frame rate is a
  demuxer constant (15 fps), not a file field.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `smush/ronin_part.znm` (640×480 sanm, 131 frames,
  adpcm_vima 22050 Hz/2 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: magic
    contents: SANM
    doc: SANM signature (version-1 Smush).
  - id: movie_size
    type: u4
    doc: Declared movie size.  Lies on truncated FATE partials.
  - id: shdr_tag
    contents: SHDR
    doc: Stream-header chunk tag.
  - id: len_shdr
    type: u4
    valid:
      min: 14
    doc: SHDR payload size in bytes.
  - id: shdr
    type: shdr_body
    size: len_shdr
    doc: Frame count and video geometry.
  - id: flhd_tag
    contents: FLHD
    doc: File-header chunk tag (audio and extra metadata).
  - id: len_flhd
    type: u4
    valid:
      min: 16
    doc: FLHD payload size in bytes.
  - id: flhd
    type: flhd_body
    size: len_flhd
    doc: FLHD subchunks through the first Wave.
  - id: packets
    size-eos: true
    doc: Uninterpreted FRME/Wave/Bl16 packets.

instances:
  width:
    value: shdr.width
    doc: Frame width from SHDR.
  height:
    value: shdr.height
    doc: Frame height from SHDR.
  num_frames:
    value: shdr.nframes
    doc: Declared frame count (ffprobe nb_frames).
  audio_sample_rate:
    value: flhd.wave.sample_rate
    doc: Sample rate from the first FLHD Wave chunk.
  audio_channels:
    value: flhd.wave.channels
    doc: Channel count from the first FLHD Wave chunk.
  codec_label:
    value: '"sanm"'
    doc: ffprobe video codec_name.  SANM video has no fourcc.
  audio_codec_label:
    value: '"adpcm_vima"'
    doc: ffprobe audio codec_name.  Wave audio is always VIMA.

types:
  shdr_body:
    seq:
      - id: subversion
        type: u2le
        doc: SHDR subversion (1 in the FATE head).
      - id: nframes
        type: u4le
        valid:
          min: 1
        doc: Declared video frame count.
      - id: pad1
        type: u2le
        doc: Unused SHDR word.
      - id: width
        type: u2le
        valid:
          min: 1
        doc: Frame width in pixels.
      - id: height
        type: u2le
        valid:
          min: 1
        doc: Frame height in pixels.
      - id: pad2
        type: u2le
        doc: Trailing SHDR word (3 in the FATE head).
      - id: rest
        size-eos: true
        doc: Remainder of the SHDR payload (palette / unused).

  flhd_body:
    seq:
      - id: chunks
        type: flhd_chunk
        repeat: until
        repeat-until: _.is_wave or _io.eof
        doc: FLHD subchunks through the first Wave.
      - id: rest
        size-eos: true
        doc: Remaining FLHD bytes after Wave (further Bl16/ANNO).
    instances:
      wave:
        value: chunks.last.body.as<wave_body>
        doc: Body of the first Wave subchunk.

  flhd_chunk:
    seq:
      - id: tag
        type: u4
        enum: flhd_tag
        valid:
          any-of:
            - flhd_tag::wave
            - flhd_tag::bl16
            - flhd_tag::anno
        doc: FLHD subchunk fourcc (Wave, Bl16, ANNO).
      - id: len_body
        type: u4
        doc: Subchunk payload size.
      - id: body
        size: len_body
        type:
          switch-on: tag
          cases:
            flhd_tag::wave: wave_body
            _: raw_payload
        doc: Wave parameters, or uninterpreted Bl16/ANNO bytes.
    instances:
      is_wave:
        value: tag == flhd_tag::wave

  raw_payload:
    seq:
      - id: data
        size-eos: true
        doc: Uninterpreted FLHD subchunk payload.

  wave_body:
    seq:
      - id: sample_rate
        type: u4le
        valid:
          min: 1
        doc: Audio sample rate in Hz.
      - id: channels
        type: u4le
        valid:
          min: 1
        doc: Audio channel count.
      - id: extra
        size-eos: true
        doc: Remainder of the Wave payload.

enums:
  flhd_tag:
    0x57617665: wave
    0x426c3136: bl16
    0x414e4e4f: anno

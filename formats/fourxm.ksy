meta:
  id: fourxm
  title: 4X Technologies 4XM header
  endian: le
doc: |
  4X Technologies movie (4XM) container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/4xm.c):

  * RIFF + u32le size + 4XMV.  RIFF size lies on this
    truncated FATE partial and does not bound the walk.
  * LIST HEAD:
      LIST HNFO (name/info/std_); std_ word 1 is an IEEE
      float frame rate (15.0 here).
      LIST TRK_ containing LIST VTRK (vtrk 0x44: width at
      +36, height at +40) and LIST STRK (strk 0x28:
      adpcm, channels, sample rate, bits).
  * LIST MOVI packets after HEAD (uninterpreted).

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `4xm/version1.4xm` (640×480 4xm @ 15 fps + pcm_s16le
  22050 Hz/2 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: riff_tag
    contents: RIFF
    doc: RIFF container tag.
  - id: riff_size
    type: u4
    doc: |
      Declared RIFF size.  Lies on truncated FATE partials.
  - id: form_type
    contents: 4XMV
    doc: 4X movie form type.
  - id: head_tag
    contents: LIST
    doc: HEAD list tag.
  - id: len_head
    type: u4
    valid:
      min: 16
    doc: HEAD list payload size (type + children).
  - id: head_type
    contents: HEAD
    doc: HEAD list type.
  - id: head
    type: head_body
    size: len_head - 4
    doc: HNFO plus TRK_ lists.
  - id: packets
    size-eos: true
    doc: LIST MOVI and frame packets (uninterpreted).

instances:
  width:
    value: head.tracks.vtrk_list.vtrk.frame_width
    doc: Video width from the vtrk chunk.
  height:
    value: head.tracks.vtrk_list.vtrk.frame_height
    doc: Video height from the vtrk chunk.
  fps:
    value: head.hnfo.std.fps.to_i
    doc: Integer fps from the std_ IEEE float (av_d2q).
  audio_sample_rate:
    value: head.tracks.strk_list.strk.sample_rate
    doc: Sample rate from the strk chunk.
  audio_channels:
    value: head.tracks.strk_list.strk.channels
    doc: Channel count from the strk chunk.
  audio_bits:
    value: head.tracks.strk_list.strk.bits
    doc: Bits per sample from the strk chunk.
  audio_bit_rate:
    value: audio_channels * audio_sample_rate * audio_bits
    doc: ffprobe audio bit_rate (channels × rate × bits).
  codec_label:
    value: '"4xm"'
    doc: ffprobe video codec_name.  4XM video has no fourcc.
  audio_codec_label:
    value: 'head.tracks.strk_list.strk.adpcm != 0 ? "adpcm_4xm" : (audio_bits == 8 ? "pcm_u8" : "pcm_s16le")'
    doc: ffprobe audio codec_name from strk adpcm/bits.

types:
  head_body:
    seq:
      - id: hnfo
        type: hnfo_list
        doc: HNFO list (title, info, std_ rate).
      - id: tracks
        type: trk_list
        doc: TRK_ list (VTRK + STRK).

  hnfo_list:
    seq:
      - id: list_tag
        contents: LIST
      - id: len_list
        type: u4
      - id: list_type
        contents: HNFO
      - id: chunks
        type: hnfo_chunk
        repeat: until
        repeat-until: _.is_std
        doc: HNFO subchunks through std_.
    instances:
      std:
        value: chunks.last.body.as<std_body>
        doc: Body of the std_ rate chunk.

  hnfo_chunk:
    seq:
      - id: chunk_id
        type: str
        size: 4
        encoding: ASCII
        valid:
          any-of:
            - '"name"'
            - '"info"'
            - '"std_"'
      - id: len_body
        type: u4
      - id: body
        size: len_body
        type:
          switch-on: chunk_id
          cases:
            '"std_"': std_body
            _: raw_payload
      - id: pad
        size: len_body % 2
    instances:
      is_std:
        value: chunk_id == "std_"

  std_body:
    seq:
      - id: unknown
        type: u4
        doc: First std_ word (unused by the demuxer).
      - id: fps
        type: f4
        valid:
          expr: _ > 0.1 and _ < 1000.0
        doc: Frame rate as IEEE-754 float.

  trk_list:
    seq:
      - id: list_tag
        contents: LIST
      - id: len_list
        type: u4
      - id: list_type
        contents: 'TRK_'
      - id: vtrk_list
        type: vtrk_list
        doc: Video track list.
      - id: strk_list
        type: strk_list
        doc: Sound track list.

  vtrk_list:
    seq:
      - id: list_tag
        contents: LIST
      - id: len_list
        type: u4
      - id: list_type
        contents: VTRK
      - id: chunks
        type: vtrk_chunk
        repeat: until
        repeat-until: _.is_vtrk
    instances:
      vtrk:
        value: chunks.last.body.as<vtrk_body>

  vtrk_chunk:
    seq:
      - id: chunk_id
        type: str
        size: 4
        encoding: ASCII
        valid:
          any-of:
            - '"name"'
            - '"vtrk"'
      - id: len_body
        type: u4
      - id: body
        size: len_body
        type:
          switch-on: chunk_id
          cases:
            '"vtrk"': vtrk_body
            _: raw_payload
      - id: pad
        size: len_body % 2
    instances:
      is_vtrk:
        value: chunk_id == "vtrk"

  vtrk_body:
    seq:
      - id: skip
        size: 28
        doc: vtrk prefix before geometry (extradata lives at +8).
      - id: frame_width
        type: u4
        valid:
          min: 1
        doc: Video width (vtrk +36).
      - id: frame_height
        type: u4
        valid:
          min: 1
        doc: Video height (vtrk +40).
      - id: rest
        size-eos: true

  strk_list:
    seq:
      - id: list_tag
        contents: LIST
      - id: len_list
        type: u4
      - id: list_type
        contents: STRK
      - id: chunks
        type: strk_chunk
        repeat: until
        repeat-until: _.is_strk
    instances:
      strk:
        value: chunks.last.body.as<strk_body>

  strk_chunk:
    seq:
      - id: chunk_id
        type: str
        size: 4
        encoding: ASCII
        valid:
          any-of:
            - '"name"'
            - '"strk"'
      - id: len_body
        type: u4
      - id: body
        size: len_body
        type:
          switch-on: chunk_id
          cases:
            '"strk"': strk_body
            _: raw_payload
      - id: pad
        size: len_body % 2
    instances:
      is_strk:
        value: chunk_id == "strk"

  strk_body:
    seq:
      - id: track
        type: u4
        doc: Track index (strk +8).
      - id: adpcm
        type: u4
        doc: Non-zero selects ADPCM 4XM.
      - id: skip
        size: 20
        doc: Unused strk middle (strk +16 through +35).
      - id: channels
        type: u4
        valid:
          min: 1
        doc: Channel count (strk +36).
      - id: sample_rate
        type: u4
        valid:
          min: 1
        doc: Sample rate in Hz (strk +40).
      - id: bits
        type: u4
        valid:
          any-of: [8, 16]
        doc: Bits per sample (strk +44).

  raw_payload:
    seq:
      - id: data
        size-eos: true

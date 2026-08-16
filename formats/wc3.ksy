meta:
  id: wc3
  title: Westwood Wing Commander III movie header
  endian: be
doc: |
  Westwood Wing Commander III movie (wc3movie, .MVE) — header unit.

  Not Interplay MVE (`ipmovie`).  Same extension, different
  container (FORM/MOVE).

  Layout (FFmpeg 6.1.1 libavformat/wc3movie.c):

  * IFF FORM + u32be size + MOVE.  FORM size lies on this
    truncated FATE partial and does not bound the walk.
  * Header chunks until BRCH: _PC_ (palette count), SOND,
    zero or more 768-byte PALT palettes, optional BNAM/SIZE,
    INDX.  Chunk sizes are u32be, 16-bit aligned.
  * SIZE, if present, is two u32le width/height words.
    Absent SIZE uses the demuxer defaults 320×165 (this
    FATE head has no SIZE).
  * Audio is always PCM s16le 22050 Hz/1 ch; those numbers
    and 15 fps are format constants, not file fields.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `wc3movie/SC_32-part.MVE` (320×165 xan_wc3 + pcm_s16le
  22050 Hz/1 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: form_tag
    contents: 'FORM'
    doc: IFF container tag.
  - id: form_size
    type: u4
    doc: |
      Size of everything after this field (big-endian IFF).
      May exceed the on-disk length for truncated FATE partials.
  - id: form_type
    contents: 'MOVE'
    doc: IFF form type.  Probe also accepts the following _PC_.
  - id: chunks
    type: iff_chunk
    repeat: until
    repeat-until: _.is_brch
    doc: IFF chunks through the first BRCH.
  - id: packets
    size-eos: true
    doc: SHOT/VGA/AUDI/TEXT packets after BRCH (uninterpreted).

instances:
  width:
    value: 320
    doc: |
      WC3_DEFAULT_WIDTH.  A SIZE chunk would override this; the
      FATE head has none, so ffprobe reports the format default.
  height:
    value: 165
    doc: |
      WC3_DEFAULT_HEIGHT.  A SIZE chunk would override this; the
      FATE head has none, so ffprobe reports the format default.
  palette_count:
    value: chunks.first.body.as<pc_body>.palette_count
    doc: Palette count from the leading _PC_ chunk (third u32le).
  palt_walked:
    value: chunks.size - 4
    doc: |
      Header chunks minus _PC_, SOND, INDX, and BRCH — the PALT
      run on this layout.  Equals palette_count.
  audio_sample_rate:
    value: 22050
    doc: WC3_SAMPLE_RATE.  Format constant, not a file field.
  audio_channels:
    value: 1
    doc: WC3_AUDIO_CHANNELS.  Format constant, not a file field.
  audio_bit_rate:
    value: 22050 * 16 * 1
    doc: ffprobe audio bit_rate (rate × 16-bit × mono).
  codec_label:
    value: '"xan_wc3"'
    doc: ffprobe video codec_name.  WC3 video has no fourcc.
  audio_codec_label:
    value: '"pcm_s16le"'
    doc: ffprobe audio codec_name.  WC3 audio is always s16le.

types:
  iff_chunk:
    seq:
      - id: chunk_id
        type: str
        size: 4
        encoding: ASCII
        valid:
          any-of:
            - '"_PC_"'
            - '"SOND"'
            - '"PALT"'
            - '"INDX"'
            - '"BRCH"'
            - '"BNAM"'
            - '"SIZE"'
        doc: Four-character IFF chunk identifier.
      - id: len_body
        type: u4
        doc: Declared payload size (big-endian, before pad).
      - id: body
        size: padded_len
        type:
          switch-on: chunk_id
          cases:
            '"SIZE"': size_body
            '"_PC_"': pc_body
            _: raw_payload
        doc: SIZE geometry, _PC_ palette count, or raw bytes.
    instances:
      padded_len:
        value: (len_body + 1) & 4294967294
        doc: Payload plus IFF pad ((size + 1) & ~1).
      is_brch:
        value: chunk_id == "BRCH"
      is_size:
        value: chunk_id == "SIZE"
      is_pc:
        value: chunk_id == "_PC_"
      is_palt:
        value: chunk_id == "PALT"

  size_body:
    seq:
      - id: frame_width
        type: u4le
        valid:
          min: 1
        doc: Video width override (little-endian).
      - id: frame_height
        type: u4le
        valid:
          min: 1
        doc: Video height override (little-endian).
      - id: extra
        size-eos: true
        doc: Remainder of a padded SIZE payload.

  pc_body:
    seq:
      - id: unknown1
        type: u4le
        doc: First _PC_ word (1 in the FATE head).
      - id: unknown2
        type: u4le
        doc: Second _PC_ word (0 in the FATE head).
      - id: palette_count
        type: u4le
        valid:
          min: 1
        doc: Number of following PALT chunks.
      - id: extra
        size-eos: true
        doc: Remainder of a padded _PC_ payload.

  raw_payload:
    seq:
      - id: data
        size-eos: true
        doc: Uninterpreted header-chunk payload.

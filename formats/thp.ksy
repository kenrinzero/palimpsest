meta:
  id: thp
  title: Nintendo GameCube THP header and component table
  endian: be
doc: |
  Nintendo GameCube THP container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/thp.c):

  * 48-byte file header (magic, version, buffer/sample maxima,
    fps float, frame count, frame/data offsets)
  * component table at `component_data_offset`: count, 16-byte
    type list, then one record per listed component
  * video (type 0): width, height; version 0x11000 adds a pad u32
  * audio (type 1): channels, sample rate, sample count
  * frame payload at `first_frame_offset` (uninterpreted; this
    FATE head is a 1 MiB partial of a ~189 MiB movie)

  This unit requires one video and one audio component.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `thp/pikmin2-opening1-partial.thp` (608×320 thp + adpcm_thp
  32000 Hz/2 ch, 6500 declared frames).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: magic
    contents: [0x54, 0x48, 0x50, 0x00]
    doc: THP signature ("THP" + NUL).
  - id: version
    type: u4
    doc: Container version.  0x00011000 adds a u32 after video geometry.
  - id: max_buffer_size
    type: u4
    doc: Maximum per-frame buffer size.
  - id: max_audio_samples
    type: u4
    doc: Maximum audio samples per frame.
  - id: fps
    type: f4
    valid:
      expr: _ > 0.1 and _ < 1000.0
    doc: Frames per second as IEEE-754 float (FFmpeg reduces it via av_d2q).
  - id: num_frames
    type: u4
    valid:
      min: 1
    doc: Declared video frame count (ffprobe nb_frames, not duration_ts).
  - id: first_frame_size
    type: u4
    valid:
      min: 1
    doc: Size of the first frame record.
  - id: movie_data_size
    type: u4
    doc: Declared movie data size.  Lies on truncated FATE partials.
  - id: component_data_offset
    type: u4
    valid:
      min: 48
    doc: Absolute file offset of the component table.
  - id: offsets_data_offset
    type: u4
    doc: Offset table pointer (0 when unused).
  - id: first_frame_offset
    type: u4
    valid:
      min: 48
    doc: Absolute file offset of the first frame.
  - id: last_frame_offset
    type: u4
    doc: Absolute file offset of the last frame.

instances:
  component_table:
    pos: component_data_offset
    type: component_table
    doc: Component count, type list, and per-component records.
  width:
    value: >
      component_table.components[0].is_video ?
        component_table.components[0].width :
        component_table.components[1].width
    doc: Frame width from the video component.
  height:
    value: >
      component_table.components[0].is_video ?
        component_table.components[0].height :
        component_table.components[1].height
    doc: Frame height from the video component.
  audio_sample_rate:
    value: >
      component_table.components[0].is_audio ?
        component_table.components[0].sample_rate :
        component_table.components[1].sample_rate
    doc: Audio sample rate from the audio component.
  audio_channels:
    value: >
      component_table.components[0].is_audio ?
        component_table.components[0].channels :
        component_table.components[1].channels
    doc: Audio channel count from the audio component.
  audio_num_samples:
    value: >
      component_table.components[0].is_audio ?
        component_table.components[0].num_samples :
        component_table.components[1].num_samples
    doc: Declared audio sample count (ffprobe audio duration_ts).
  walked_component_count:
    value: component_table.components.size
    doc: Number of component records actually walked.
  codec_label:
    value: '"thp"'
    doc: ffprobe video codec_name.  THP video has no fourcc.
  audio_codec_label:
    value: '"adpcm_thp"'
    doc: ffprobe audio codec_name.  THP audio is always ADPCM THP.

types:
  component_table:
    seq:
      - id: num_components
        type: u4
        valid:
          eq: 2
        doc: Number of components that follow the 16-byte type list.
      - id: component_types
        type: u1
        repeat: expr
        repeat-expr: 16
        doc: Type bytes.  0 = video, 1 = audio; remaining slots are 0xFF.
      - id: av_pair
        size: 0
        valid:
          expr: >
            (component_types[0] == 0 and component_types[1] == 1) or
            (component_types[0] == 1 and component_types[1] == 0)
        doc: This unit requires one video and one audio component.
      - id: components
        type: component(component_types[_index])
        repeat: expr
        repeat-expr: num_components
        doc: Per-component records in type-list order.

  component:
    params:
      - id: kind
        type: u1
    seq:
      - id: width
        type: u4
        if: is_video
        valid:
          min: 1
        doc: Frame width in pixels.
      - id: height
        type: u4
        if: is_video
        valid:
          min: 1
        doc: Frame height in pixels.
      - id: version_pad
        type: u4
        if: is_video and _root.version == 0x11000
        doc: Extra word present only on version 0x11000 (skipped by FFmpeg).
      - id: channels
        type: u4
        if: is_audio
        valid:
          min: 1
        doc: Audio channel count.
      - id: sample_rate
        type: u4
        if: is_audio
        valid:
          min: 1
        doc: Audio sample rate in Hz.
      - id: num_samples
        type: u4
        if: is_audio
        valid:
          min: 1
        doc: Declared audio sample count.
    instances:
      is_video:
        value: kind == 0
      is_audio:
        value: kind == 1

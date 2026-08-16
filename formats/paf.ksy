meta:
  id: paf
  title: Amazing Studio Packed Animation File header
  endian: le
doc: |
  Amazing Studio Packed Animation File (PAF) — header unit.

  Layout (FFmpeg 6.1.1 libavformat/paf.c):

  * "Packed Animation File V1.0" plus copyright / DOS EOF
  * demuxer skips 132 bytes from file start
  * u32le: frame count, frame duration (ms), width, height
  * unused u32, then buffer/preload/block table fields
  * tables and payload after buffer_size (uninterpreted)

  Audio is always PAF ADPCM, 22050 Hz stereo — those
  numbers are format constants.  Frame rate is 1000 /
  frame_ms.

  Proven against ffprobe 6.1.1-3ubuntu5 on FATE
  `paf/hod1-partial.paf` (256×192 paf_video @ 10 fps +
  paf_audio 22050 Hz/2 ch).  Gallery: **net-new**.
  Independence: **third-party**.

seq:
  - id: magic
    contents: "Packed Animation File V1.0"
    doc: PAF signature.  The copyright tail and DOS EOF follow.
  - id: header_pad
    size: 132 - 26
    doc: Copyright, DOS EOF, and padding.  Demuxer skips 132 from 0.
  - id: nb_frames
    type: u4
    valid:
      min: 1
    doc: Declared frame count (ffprobe video duration_ts).
  - id: frame_ms
    type: u4
    valid:
      min: 1
    doc: Frame duration in milliseconds.  Time base is frame_ms/1000.
  - id: width
    type: u4
    valid:
      min: 1
    doc: Frame width in pixels.
  - id: height
    type: u4
    valid:
      min: 1
    doc: Frame height in pixels.
  - id: unused
    type: u4
    doc: Unused word skipped by the demuxer.
  - id: buffer_size
    type: u4
    valid:
      min: 175
      max: 2048
    doc: Block size used by the later tables (uninterpreted here).
  - id: preload_count
    type: u4
    valid:
      min: 1
    doc: Number of blocks preloaded before the first frame.
  - id: frame_blks
    type: u4
    valid:
      min: 1
    doc: Number of frame-block table entries.
  - id: start_offset
    type: u4
    doc: File offset of the first payload block.
  - id: max_video_blks
    type: u4
    valid:
      min: 1
    doc: Maximum video blocks per working buffer.
  - id: max_audio_blks
    type: u4
    valid:
      min: 2
    doc: Maximum audio blocks per working buffer.
  - id: rest
    size-eos: true
    doc: Block tables and interleaved payload (uninterpreted).

instances:
  fps:
    value: 1000 / frame_ms
    doc: Frames per second (1000 / frame_ms).
  audio_sample_rate:
    value: 22050
    doc: PAF audio rate.  Format constant, not a file field.
  audio_channels:
    value: 2
    doc: PAF audio is always stereo.  Format constant.
  codec_label:
    value: '"paf_video"'
    doc: ffprobe video codec_name.  PAF video has no fourcc.
  audio_codec_label:
    value: '"paf_audio"'
    doc: ffprobe audio codec_name.  PAF audio has no fourcc.

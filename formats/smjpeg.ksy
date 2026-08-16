meta:
  id: smjpeg
  title: Loki SDL Motion JPEG header and packet stream
  endian: be
doc: |
  Loki SDL Motion JPEG (SMJPEG) container — header unit.

  Layout (FFmpeg 6.1.1 libavformat/smjpegdec.c / smjpegenc.c):

  * 8-byte magic 00 0A "SMJPEG"
  * u32be version (0), u32be duration in milliseconds
  * header chunks (_TXT / _SND / _VID) until HEND
  * data packets (vidD / sndD: pts, size, payload) until DONE

  Fourcc tags are little-endian; numeric fields are big-endian.
  This unit's fixture is video-only (no comment, no audio), so the
  first header chunk must be _VID.

  Proven against ffprobe 6.1.1-3ubuntu5 on a self-generated 32×24
  MJPEG clip.  Gallery: **net-new**. Independence: **self-generated**.

seq:
  - id: magic
    contents: [0x00, 0x0a, 0x53, 0x4d, 0x4a, 0x50, 0x45, 0x47]
    doc: SMJPEG signature (NUL, LF, "SMJPEG").
  - id: version
    type: u4
    valid:
      eq: 0
    doc: Container version.  Non-zero is request_sample in FFmpeg 6.1.1.
  - id: duration_ms
    type: u4
    valid:
      min: 1
    doc: Duration in milliseconds (stream time base 1/1000).
  - id: header_chunks
    type: header_chunk
    repeat: until
    repeat-until: _.is_hend
    doc: Header chunks through HEND.
  - id: packets
    type: data_packet
    repeat: until
    repeat-until: _.is_done
    doc: vidD/sndD packets through DONE.

types:
  header_chunk:
    seq:
      - id: type
        type: u4le
        enum: htype
        valid:
          any-of:
            - htype::txt
            - htype::snd
            - htype::vid
            - htype::hend
        doc: Header fourcc (_TXT, _SND, _VID, HEND).
      - id: len_body
        type: u4
        if: not is_hend
        valid:
          expr: 'is_vid ? _ >= 12 : (is_snd ? _ >= 8 : _ > 0)'
        doc: Header payload size.  Absent on HEND.
      - id: vid
        type: vid_header
        if: is_vid
        doc: Video stream description.
      - id: extra
        size: 'is_vid ? len_body - 12 : (is_hend ? 0 : len_body)'
        if: not is_hend
        doc: Remainder of this header payload (comments, audio, pad).
    instances:
      is_hend:
        value: type == htype::hend
      is_vid:
        value: type == htype::vid
      is_snd:
        value: type == htype::snd

  vid_header:
    seq:
      - id: nb_frames
        type: u4
        doc: Declared frame count (0 in the generated fixture).
      - id: width
        type: u2
        valid:
          min: 1
        doc: Frame width in pixels.
      - id: height
        type: u2
        valid:
          min: 1
        doc: Frame height in pixels.
      - id: codec_tag
        type: u4le
        valid:
          eq: 0x4649464a
        doc: Video fourcc.  0x4649464A = JFIF (MJPEG).

  data_packet:
    seq:
      - id: type
        type: u4le
        enum: ptype
        valid:
          any-of:
            - ptype::vidd
            - ptype::sndd
            - ptype::done
        doc: Packet fourcc (vidD, sndD, DONE).
      - id: pts
        type: u4
        if: not is_done
        doc: Presentation timestamp in milliseconds.
      - id: len_body
        type: u4
        if: not is_done
        doc: Packet payload size.
      - id: body
        size: len_body
        if: not is_done
        doc: Uninterpreted MJPEG (or audio) payload.
    instances:
      is_done:
        value: type == ptype::done

enums:
  htype:
    0x5458545f: txt
    0x444e535f: snd
    0x4449565f: vid
    0x444e4548: hend
  ptype:
    0x44646976: vidd
    0x44646e73: sndd
    0x454e4f44: done

instances:
  first_header:
    value: header_chunks[0]
    doc: First header chunk.  This video-only fixture places _VID first.
  width:
    value: first_header.vid.width
    doc: Frame width from the leading _VID chunk.
  height:
    value: first_header.vid.height
    doc: Frame height from the leading _VID chunk.
  codec_label:
    value: '"mjpeg"'
    doc: ffprobe codec_name for the JFIF video tag.
  walked_packet_count:
    value: packets.size
    doc: Data packets walked, including the DONE terminator.

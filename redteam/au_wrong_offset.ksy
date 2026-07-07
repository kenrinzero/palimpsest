meta:
  id: au_wrong_offset
  title: RED-TEAM (a) — deliberately WRONG AU header; must go RED on the differential
  endian: be
doc: |
  Compiles fine, parses fine — but `sample_rate` is declared at the
  ENCODING field's offset (real AU header: magic, data_offset, data_size,
  encoding, sample_rate, channels). Against a real sample the parsed
  "sample_rate" is the encoding code (3 = pcm_s16be), not 8000 — the
  differential gate must catch exactly this class of wrong-but-compilable
  spec. NEVER fix this file; it is a fixture.
seq:
  - id: magic
    contents: '.snd'
  - id: data_offset
    type: u4
  - id: data_size
    type: u4
  - id: sample_rate   # WRONG on purpose: this offset holds `encoding`
    type: u4
  - id: encoding      # WRONG on purpose: this offset holds the real rate
    type: u4
  - id: channels
    type: u4

meta:
  id: toy_compilefail
  title: RED-TEAM (b) — must FAIL the compile gate
  endian: be
seq:
  - id: broken
    type: u9_no_such_type
  - id: also_broken
    size: not_a_number

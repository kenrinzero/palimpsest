meta:
  id: au_null_oracle
  file-extension: au
  endian: be
seq:
  - id: magic
    contents: [0x2e, 0x73, 0x6e, 0x64]
  - id: data_offset
    type: u4
  - id: data_size
    type: u4
  - id: encoding
    type: u4
  - id: sample_rate
    type: u4
  - id: channels
    type: u4
instances:
  null_label:
    value: '"null"'

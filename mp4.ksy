meta:
  id: mp4
  file-extension: mp4
  endian: be

seq:
  - id: boxes
    type: box
    repeat: eos

types:

  box:
    seq:
      - id: length
        type: u4
      - id: type
        type: u4
        enum: fourcc
      - id: extended_length
        type: u8
        if: length == 1
      - id: data
        size: '(length == 1) ? (extended_length - 16) : (length - 8)'
        type:
          switch-on: type
          cases:
            fourcc::avc1: avc1
            fourcc::dinf: box_container
            fourcc::dref: dref
            fourcc::edts: box_container
            fourcc::mdia: box_container
            fourcc::meta: box_container
            fourcc::minf: box_container
            fourcc::moov: box_container
            fourcc::proj: box_container
            fourcc::stbl: box_container
            fourcc::stsd: stsd
            fourcc::sv3d: box_container
            fourcc::trak: box_container
            fourcc::uuid: uuid
            fourcc::ytmp: ytmp
            
            # https://developer.apple.com/library/archive/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html
            # fourcc::hdlr: hdlr # Handler Reference
            fourcc::mvhd: mvhd # Movie Header
            fourcc::stco: stco # Chunk Offset Atoms
            fourcc::stsc: stsc # Sample-to-Chunk Atoms
            fourcc::stsz: stsz # Sample Size Atoms
            fourcc::stts: stts # Time-to-Sample Atoms
            fourcc::tkhd: tkhd # Track Header Atoms
            
    -webide-representation: '{type}'

  box_container:
    seq:
      - id: boxes
        type: box
        repeat: eos

  dref:
    seq:
      - id: unknown_x0
        size: 8
      - id: boxes
        type: box
        repeat: eos

  stsd:
    seq:
      - id: version
        type: u1
      - id: flags
        size: 3
      - id: num_entries
        type: u4
      - id: boxes
        type: box
        repeat: eos

  avc1:
    seq:
      - id: unknown_x0
        size: 78
      - id: boxes
        type: box
        repeat: eos

  # From old RFC for spherical video
  # https://github.com/google/spatial-media/blob/master/docs/spherical-video-rfc.md
  uuid:
    seq:
      - id: uuid
        size: 16
      - id: xml_metadata
        size-eos: true

  ytmp:
    seq:
      - id: unknown_x0
        type: u4
      - id: crc
        type: u4
      - id: encoding
        type: u4
        enum: fourcc
      - id: payload
        type:
          switch-on: encoding
          cases:
            fourcc::dfl8: ytmp_payload_zlib

  ytmp_payload_zlib:
    seq:
      - id: data
        size-eos: true
        #process: zlib

  hdlr:
    seq:
      - id: version
        type: u1
      - id: flags
        size: 3
      - id: component_type
        type: u4
        enum: fourcc
      - id: component_subtype
        type: u4
        enum: fourcc
      - id: component_name
        size-eos: true

  mvhd:
    seq:
      - id: version
        type: u1
      - id: flags
        size: 3
      - id: creation_time
        type: u4
      - id: modification_time
        type: u4
      - id: time_scale
        type: u4
      - id: duration
        type: u4
      - id: preferred_rate
        type: u4
      - id: preferred_volume
        type: u2
      - id: reserved
        size: 10
      - id: matrix_structure
        type: u4
        repeat: expr
        repeat-expr: 9
      - id: preview_time
        type: u4
      - id: preview_duration
        type: u4
      - id: poster_time
        type: u4
      - id: selection_time
        type: u4
      - id: selection_duration
        type: u4
      - id: current_time
        type: u4
      - id: next_track_id
        type: u4
  stco:
    seq:
      - id: version
        type: u1
      - id: flags
        size: 3
      - id: entries_num
        type: u4
      - id: offsets
        type: u4
        repeat: expr
        repeat-expr: entries_num

  stsc_entry:
    seq:
      - id: first_chunk
        type: u4
      - id: samples_per_chunk
        type: u4
      - id: sample_description_id
        type: u4

  stsc:
    seq:
      - id: version
        type: u1
      - id: flags
        size: 3
      - id: entries_num
        type: u4
      - id: chunks
        type: stsc_entry
        repeat: expr
        repeat-expr: entries_num

  stsz:
    seq:
      - id: version
        type: u1
      - id: flags
        size: 3
      - id: sample_size
        type: u4
      - id: entries_num
        type: u4
      - id: sizes
        if: sample_size == 0
        type: u4
        repeat: expr
        repeat-expr: entries_num

  stts_entry:
    seq:
      - id: number_of_entries
        type: u4
      - id: sample_duration
        type: u4

  stts:
    seq:
      - id: version
        type: u1
      - id: flags
        size: 3
      - id: entries_num
        type: u4
      - id: time_to_sample
        type: stts_entry
        repeat: expr
        repeat-expr: entries_num

  tkhd:
    seq:
      - id: version
        type: u1
      - id: flags
        size: 3
      - id: creation_time
        type: u4
      - id: modification_time
        type: u4
      - id: track_id
        type: u4
      - id: reserved0
        type: u4
      - id: duration
        type: u4
      - id: reserved1
        type: u8
      - id: layer
        type: u2
      - id: alternate_group
        type: u2
      - id: volume
        type: u2
      - id: reserved2
        type: u2
      - id: matrix_structure
        type: u4
        repeat: expr
        repeat-expr: 9
      - id: track_width
        type: u4
      - id: track_height
        type: u4
enums:

  fourcc:
    0x61766331: avc1
    0x61766343: avc_c
    0x64666C38: dfl8
    0x64696E66: dinf
    0x64726566: dref
    0x65647473: edts
    0x656C7374: elst
    0x66747970: ftyp
    0x68646C72: hdlr
    0x6D646174: mdat
    0x6D646864: mdhd
    0x6D646961: mdia
    0x6D657461: meta
    0x6D696E66: minf
    0x6D6F6F66: moof
    0x6D6F6F76: moov
    0x6D766578: mvex
    0x6D766864: mvhd
    0x70726864: prhd
    0x70726F6A: proj
    0x73696478: sidx
    0x73743364: st3d
    0x7374626C: stbl
    0x7374636F: stco
    0x73747363: stsc
    0x73747364: stsd
    0x73747373: stss
    0x7374737A: stsz
    0x73747473: stts
    0x73763364: sv3d
    0x73766864: svhd
    0x74657874: text
    0x746B6864: tkhd
    0x7472616B: trak
    0x75726C20: url
    0x75756964: uuid
    0x766D6864: vmhd
    0x79746D70: ytmp

///|
test "non-ASCII letters count as Unicode letters, ASCII and digits do not" {
  let codes = [
    0x41, 0xa9, 0xaa, 0xab, 0xb5, 0xc0, 0xd7, 0x3b1, 0x4e00, 0x3042, 0x30a2, 0xac00,
    0xffdc, 0xffdd, 0xff21, 0x660, 0x2160, 0x10000,
  ]
  let marks = codes.map(c => if @util.is_unicode_letter(c) { "1" } else { "0" })
  inspect(marks.join(""), content="001011011111101000")
}

///|
test "the letter table has as many letters and ranges as pele's" {
  let mut count = 0
  let mut ranges = 0
  let mut prev = false
  for c in 0..<=0x10000 {
    let letter = @util.is_unicode_letter(c)
    if letter {
      count += 1
    }
    if letter && !prev {
      ranges += 1
    }
    prev = letter
  }
  inspect(
    "\{count} letters in \{ranges} ranges",
    content="48410 letters in 368 ranges",
  )
}

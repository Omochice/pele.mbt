///|
test "titles of series are trimmed for their legends" {
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_band(["90d", "60d"])
  db.set_line_data(" avg ", points([48.1, 41.5]))
  db.set_bar_data(" p95 ", points([112.2, 75.3]))
  inspect(
    dump(db),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" ["90d","60d"]) set=true
      #|y="" 41.5..112.2 set=false
      #|line "avg" ["90d"=48.1,"60d"=41.5] labels=-
      #|bar "p95" ["90d"=112.2,"60d"=75.3] labels=-
    ),
  )
}

///|
test "values beyond the categories are dropped" {
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_band(["cat1", "cat2", "cat3"])
  db.set_bar_data("testBar", points([10, 20, 30, 40, 50]))
  inspect(
    last_line(db),
    content=(
      #|bar "testBar" ["cat1"=10,"cat2"=20,"cat3"=30] labels=-
    ),
  )
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_band(["A", "B"])
  db.set_line_data("testLine", points([100, 200, 300, 400]))
  inspect(
    last_line(db),
    content=(
      #|line "testLine" ["A"=100,"B"=200] labels=-
    ),
  )
}

///|
test "values that match the categories are kept as they are" {
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_band(["X", "Y", "Z"])
  db.set_bar_data("exact", points([5, 10, 15]))
  inspect(
    last_line(db),
    content=(
      #|bar "exact" ["X"=5,"Y"=10,"Z"=15] labels=-
    ),
  )
}

///|
test "a category without a value stays in the series" {
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_band(["A", "B", "C", "D"])
  db.set_bar_data("short", points([1, 2]))
  inspect(
    last_line(db),
    content=(
      #|bar "short" ["A"=1,"B"=2,"C"=-,"D"=-] labels=-
    ),
  )
}

///|
test "the value range comes only from the values that are kept" {
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_band(["Q1", "Q2"])
  db.set_bar_data("sales", points([10, 50, 999, 800]))
  inspect(db.y_axis.max.to_string(), content="50")
  inspect(db.y_axis.min.to_string(), content="10")
}

///|
test "a range written for the y axis is not widened by the values" {
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_band(["a", "b"])
  db.set_y_axis_range_data(0, 5)
  db.set_bar_data("s", points([1, 50]))
  inspect(
    lines_of(db)[3],
    content=(
      #|y="" 0..5 set=true
    ),
  )
}

///|
test "the first series fixes a numeric x range when no axis did" {
  let db = @xychart.XyChartDb::new()
  db.set_line_data("", points([5, 6, 7, 8]))
  inspect(
    dump(db),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" 1..4) set=true
      #|y="" 5..8 set=false
      #|line "" ["1"=5,"2"=6,"3"=7,"4"=8] labels=-
    ),
  )
}

///|
test "values are spread over a numeric x range" {
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_range_data(0, 10)
  db.set_line_data("", points([1, 2, 3]))
  inspect(
    last_line(db),
    content=(
      #|line "" ["0"=1,"5"=2,"10"=3] labels=-
    ),
  )
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_range_data(0, 1)
  db.set_bar_data("", points([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]))
  inspect(
    last_line(db),
    content=(
      #|bar "" ["0"=1,"0.1"=2,"0.2"=3,"0.30000000000000004"=4,"0.4"=5,"0.5"=6,"0.6000000000000001"=7,"0.7000000000000001"=8,"0.8"=9,"0.9"=10,"1"=11] labels=-
    ),
  )
}

///|
test "a single value sits at the start of a numeric x range" {
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_range_data(-0.0, 10)
  db.set_line_data("", points([4]))
  inspect(
    last_line(db),
    content=(
      #|line "" ["0"=4] labels=-
    ),
  )
}

///|
test "a series with no values changes nothing" {
  let db = @xychart.XyChartDb::new()
  db.set_line_data("empty", [])
  inspect(
    dump(db),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="" Infinity..-Infinity set=false
      #|line "empty" [] labels=-
    ),
  )
}

///|
test "labels on the points of a line are trimmed and kept when any is written" {
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_band(["Q1", "Q2", "Q3"])
  db.set_line_data("", [
    { value: 25, label: " Launch ", },
    { value: 45, label: "", },
    { value: 72, label: "Target", },
  ])
  db.set_line_data("plain", [
    { value: 1, label: " ", },
    { value: 2, label: "", },
    { value: 3, label: "", },
  ])
  let lines = lines_of(db)
  inspect(
    lines[4],
    content=(
      #|line "" ["Q1"=25,"Q2"=45,"Q3"=72] labels=["Launch","","Target"]
    ),
  )
  inspect(
    lines[5],
    content=(
      #|line "plain" ["Q1"=1,"Q2"=2,"Q3"=3] labels=-
    ),
  )
}

///|
test "bars ignore the labels of their points" {
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_band(["a"])
  db.set_bar_data("", [{ value: 1, label: "ignored", }])
  inspect(
    last_line(db),
    content=(
      #|bar "" ["a"=1] labels=-
    ),
  )
}

///|
test "an axis keeps its title when its range or categories are set" {
  let db = @xychart.XyChartDb::new()
  db.set_x_axis_title("  x title ")
  db.set_x_axis_range_data(1, 2)
  db.set_y_axis_title(" y title ")
  db.set_y_axis_range_data(3, 4)
  inspect(
    dump(db),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("x title" 1..2) set=true
      #|y="y title" 3..4 set=true
    ),
  )
  db.set_x_axis_band(["a"])
  inspect(
    lines_of(db)[2],
    content=(
      #|x=band("x title" ["a"]) set=true
    ),
  )
}

///|
test "the orientation is vertical unless it is exactly horizontal" {
  let db = @xychart.XyChartDb::new()
  db.set_orientation("horizontal")
  inspect(lines_of(db)[1], content="orientation=horizontal")
  db.set_orientation("HORIZONTAL")
  inspect(lines_of(db)[1], content="orientation=vertical")
  db.set_orientation("vertical")
  inspect(lines_of(db)[1], content="orientation=vertical")
}

///|
test "accessibility texts are cleaned the way Mermaid cleans them" {
  let db = @xychart.XyChartDb::new()
  db.set_diagram_title("T")
  db.set_acc_title(" \n  Title")
  db.set_acc_description("one\n   two\n\n  three")
  inspect(
    lines_of(db)[0],
    content=(
      #|title="T" accTitle="Title" accDescr="one\ntwo\nthree"
    ),
  )
}

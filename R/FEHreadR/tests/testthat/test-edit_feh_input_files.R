

test_that("feh_read_alters() reads alter statements", {
    fname = test_path("fixtures", "rundynasipp.inp")
    df = feh_read_alters(fname)
    expect_equal(dim(df)[2], 3)
})

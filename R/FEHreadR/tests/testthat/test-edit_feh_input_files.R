

test_that("feh_read_alters() reads alter statements", {
    fname = test_path("fixtures", "rundynasipp.inp")
    df = feh_read_alters(fname)
    expect_equal(dim(df)[2], 3)
    expect_equal(unique(df$TSNAME), c("ABIRTH1","ABIRTH2","ABIRTH3","ABIRTH4","ABIRTH5","DETEST","EARNTRG"))
})

test_that("feh_update_alters() modifes ALTER statements", {
    outfname = withr::local_tempfile()
    infname = test_path("fixtures", "rundynasipp.inp")
    alterdf = data.frame(
        TSNAME="EARNTRG",
        YEAR=2025:2030,
        VALUE=50000
    )
    capture_output(
        feh_update_alters(alterdf, infname, outfname)
    )
    idf = feh_read_alters(infname)
    odf = feh_read_alters(outfname)

    expect_true(all.equal(
        dplyr::filter(idf, TSNAME != "EARNTRG", !(YEAR %in% 2025:2030)),
        dplyr::filter(odf, TSNAME != "EARNTRG", !(YEAR %in% 2025:2030))
    ))
    expect_true(all.equal(
        dplyr::filter(odf, TSNAME == "EARNTRG", YEAR %in% 2025:2030),
        alterdf
    ))
})


# SPM implementation of least squares separate

This code implements least squares separate (LSS) using SPM and MATLAB. LSS is an approach to generate single-trial beta images that circumvents problems that arise from autocorrelations in the data and the design matrix.

`least_squares_separate.m` is the main function, if you want to use it, have a look at the fairly extensive help text. `test_lss` is a poor man's version of unit testing. There is no testing for reasonable output, but it makes sure that the function runs without errors for all possible combinations of arguments to `least_squares_separate`. `testdata` contains a minimum working example of feasible input data and is used to test the main function. You can ignore it as long as you don't run into errors.

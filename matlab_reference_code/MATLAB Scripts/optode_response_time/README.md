# optode-response-time

[![File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/74579-optode-response-time) [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3975670.svg)](https://doi.org/10.5281/zenodo.3975670)

The `MATLAB` code included in this repository is designed to determine the
response time of oxygen optodes deployed on autonomous floats _in-situ_. The
process requires timestamps for each measurement and a sequence of both up- and
downcast profiles. For more information on the method see
_[Gordon et al. (2020)](https://doi.org/10.5194/bg-2020-119)_.

There are two versions of the software, the default and the
temperature-dependent version. In the default, temperature is
not taken into consideration. In the T-dependent folder, the optimization
is for boundary layer thickness, and a temperature profile must be provided
along with the oxygen profile. The temperature dependent version uses the
lookup table found in the supplement for
_[Bittig & Kortzinger (2017)](https://doi.org/10.5194/os-13-1-2017)_.

## Data

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3890240.svg)](https://doi.org/10.5281/zenodo.3890240)

This set of code was developed using autonomous float data from a GoMRI funded project.

## User Guide

The function `calculate_tau.m` is the main driver here, and calls on
`correct_oxygen_profile.m` to correct single oxygen profiles. Of course,
the user may choose to use this sub-function for their own purposes.

`calculate_tau.m` takes in matrices of depth, time, and oxygen data (see below)
and computes the optimal response time for each pair of profiles. In the
T-dependent version, the use must also supply a matrix of temperature values.
The derived time constants (or boundary layer thicknesses in T-dependent)
can then be used to correct the oxygen measurements for sensor hysteresis.
Following _[Gordon et al. (2020)](https://doi.org/10.5194/bg-2020-119)_, this
would be done using the median time constant, but we leave this decision to the
user.

### Parameters

The following parameters are optional arguments for `calculate_tau.m`:

- `zlim`: lower and upper depth bounds to perform optimization over,
default is [25,175], dimensions (1, 2)
- `zres`: resolution for profiles to be interpolated to, default is 1,
dimensions (scalar)
- `tlim`: lower and upper time constant bounds to perform optimization over,
default is [0,100], dimensions (1, 2), OR, in T-dependent mode, the lower and
upper bounds of boundary layer thickness
- `tres`: resolution to linearly step through `tlim`, default is 1
dimensions (scalar)
- `Tref`: only in T-dependent mode, reference temperature at which to report
the derived time constant (scalar)

### Input Data & Examples

Input data for `calculate_tau.m` should be in 2D matrix form, where each row is
an individual profile, and rows alternate direction of observation (for
example, all even rows could be upcasts and all odd rows downcasts or
vice-versa). Time should be in `MATLAB` datenum format. Profiles should be
organized such that time is monotonically increasing (i.e. pressure will be
monotonically decreasing for an upcast). Below is some made-up data to
demonstrate the proper data format:

```matlab
% depth matrix
PRES = [
  [200, 195, 190, .., 10, 5]; % profile 1, upcast
  [5, 10, 15, .., 195, 200 ]; % profile 2, downcast
  [200, 195, 190, .., 10, 5]; % profile 3, upcast
  ...
  [200, 195, 190, .., 10, 5]; % profile N, upcast *or* downcast
];

% time matrix, matlab datenum, monotonically increasing row to row
time = [
  [7.36451000e+05, 7.36451005e+05, 7.36451010e+05, .., 7.36451195e+05]
  [7.36451200e+05, 7.36451205e+05, 7.36451210e+05, .., 7.36451395e+05]
  ...
  [7.36454804e+05, 7.36454809e+05, 7.36454814e+05, .., 7.36455000e+05]
];

% oxygen data
DOXY = [
  % corresponding oxygen values for each time/depth
];

% get optimal tau values
tau_vals = calculate_tau(time, PRES, DOXY, 'zlim', [0,200], 'tlim', [50,110], 'tres', 0.5);
```

Using the temperature dependent mode, we just have to provide
temperature, and note that `tlim` will now represent boundary layer
thickness, not response time values. So getting the response times
reported at 20 degrees C:

```matlab
% temperature data
TEMP = [
  % corresponding temperature values for each time/depth
];

[thickness, tau_Tref] = calculate_tau_wTemp(time, PRES, DOXY, TEMP, 'tlim', [0,200], 'Tref', 20)
```

Finally, note that for both functions, pressure can easily be replaced
by density as the depth index, as long as you change the values of `zlim` to
and `zres` to appropriate values:

```matlab
% salinity data
PSAL = [
  % corresponding salinity values for each time/depth
];
PDEN = sw_pden(PSAL, TEMP, PRES, 0); % potential density using seawater package

tau_vals = calculate_tau(time, PDEN, DOXY, 'zlim', [1024, 1027], 'zres', 0.1);
```

### Test

In the `test` directory, the script `test.m` and data `example_data.mat` should
run with no changes required. This gives a very base level example of how
the functions work and the output.

### Citing and Licensing

Cite as: Gordon, C., Fennel, K., Richards, C., Shay, L. K., & Brewster, J. K.
(2020). Can ocean community production and respiration be determined by
measuring high-frequency oxygen profiles from autonomous floats?
Biogeosciences, 17(15), 4119–4134. <https://doi.org/10.5194/bg-17-4119-2020>

Please note that this code is provided as-is under the MIT license and is
subject to periodic updates and improvements. If you are interested in
contributing to this repository, please contact Christopher Gordon at
[Chris.Gordon@dfo-mpo.gc.ca](mailto:Chris.Gordon@dfo-mpo.gc.ca).

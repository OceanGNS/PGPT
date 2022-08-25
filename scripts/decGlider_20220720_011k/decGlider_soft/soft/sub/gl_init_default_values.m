% ------------------------------------------------------------------------------
% Initialize global default values.
%
% SYNTAX :
%  gl_init_default_values
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function gl_init_default_values

% global default values
global g_decGl_dateDef;
global g_decGl_epochDateDef;
global g_decGl_argosLonDef;
global g_decGl_argosLatDef;
global g_decGl_ncDateDef;
global g_decGl_ncArgosLonDef;
global g_decGl_ncArgosLatDef;

% PHASE codes
global g_decGl_phaseSurfDrift;
global g_decGl_phaseDescent;
global g_decGl_phaseSubSurfDrift;
global g_decGl_phaseInflexion;
global g_decGl_phaseAscent;
global g_decGl_phaseGrounded;
global g_decGl_phaseInconsistant;
global g_decGl_phaseDefault;

% QC flag values (numerical)
global g_decGl_qcDef;
global g_decGl_qcNoQc;
global g_decGl_qcGood;
global g_decGl_qcProbablyGood;
global g_decGl_qcCorrectable;
global g_decGl_qcBad;
global g_decGl_qcChanged;
global g_decGl_qcInterpolated;
global g_decGl_qcMissing;

% QC flag values (char)
global g_decGl_qcStrDef;
global g_decGl_qcStrNoQc;
global g_decGl_qcStrGood;
global g_decGl_qcStrProbablyGood;
global g_decGl_qcStrCorrectable;
global g_decGl_qcStrBad;
global g_decGl_qcStrChanged;
global g_decGl_qcStrUnused1;
global g_decGl_qcStrUnused2;
global g_decGl_qcStrInterpolated;
global g_decGl_qcStrMissing;

global g_decGl_janFirst1950InMatlab;
global g_decGl_janFirst200InEpoch;

global g_decGl_decoderVersion;

% DOXY coefficients
global g_decGl_doxy_201and202_201_301_d0;
global g_decGl_doxy_201and202_201_301_d1;
global g_decGl_doxy_201and202_201_301_d2;
global g_decGl_doxy_201and202_201_301_d3;
global g_decGl_doxy_201and202_201_301_sPreset;
global g_decGl_doxy_201and202_201_301_b0;
global g_decGl_doxy_201and202_201_301_b1;
global g_decGl_doxy_201and202_201_301_b2;
global g_decGl_doxy_201and202_201_301_b3;
global g_decGl_doxy_201and202_201_301_c0;
global g_decGl_doxy_201and202_201_301_pCoef2;
global g_decGl_doxy_201and202_201_301_pCoef3;

global g_decGl_doxy_201_202_202_d0;
global g_decGl_doxy_201_202_202_d1;
global g_decGl_doxy_201_202_202_d2;
global g_decGl_doxy_201_202_202_d3;
global g_decGl_doxy_201_202_202_sPreset;
global g_decGl_doxy_201_202_202_b0;
global g_decGl_doxy_201_202_202_b1;
global g_decGl_doxy_201_202_202_b2;
global g_decGl_doxy_201_202_202_b3;
global g_decGl_doxy_201_202_202_c0;
global g_decGl_doxy_201_202_202_pCoef1;
global g_decGl_doxy_201_202_202_pCoef2;
global g_decGl_doxy_201_202_202_pCoef3;

global g_decGl_doxy_202_205_302_a0;
global g_decGl_doxy_202_205_302_a1;
global g_decGl_doxy_202_205_302_a2;
global g_decGl_doxy_202_205_302_a3;
global g_decGl_doxy_202_205_302_a4;
global g_decGl_doxy_202_205_302_a5;
global g_decGl_doxy_202_205_302_d0;
global g_decGl_doxy_202_205_302_d1;
global g_decGl_doxy_202_205_302_d2;
global g_decGl_doxy_202_205_302_d3;
global g_decGl_doxy_202_205_302_sPreset;
global g_decGl_doxy_202_205_302_b0;
global g_decGl_doxy_202_205_302_b1;
global g_decGl_doxy_202_205_302_b2;
global g_decGl_doxy_202_205_302_b3;
global g_decGl_doxy_202_205_302_c0;
global g_decGl_doxy_202_205_302_pCoef1;
global g_decGl_doxy_202_205_302_pCoef2;
global g_decGl_doxy_202_205_302_pCoef3;

global g_decGl_doxy_202_205_303_a0;
global g_decGl_doxy_202_205_303_a1;
global g_decGl_doxy_202_205_303_a2;
global g_decGl_doxy_202_205_303_a3;
global g_decGl_doxy_202_205_303_a4;
global g_decGl_doxy_202_205_303_a5;
global g_decGl_doxy_202_205_303_d0;
global g_decGl_doxy_202_205_303_d1;
global g_decGl_doxy_202_205_303_d2;
global g_decGl_doxy_202_205_303_d3;
global g_decGl_doxy_202_205_303_sPreset;
global g_decGl_doxy_202_205_303_b0;
global g_decGl_doxy_202_205_303_b1;
global g_decGl_doxy_202_205_303_b2;
global g_decGl_doxy_202_205_303_b3;
global g_decGl_doxy_202_205_303_c0;
global g_decGl_doxy_202_205_303_pCoef1;
global g_decGl_doxy_202_205_303_pCoef2;
global g_decGl_doxy_202_205_303_pCoef3;

global g_decGl_doxy_202_205_304_d0;
global g_decGl_doxy_202_205_304_d1;
global g_decGl_doxy_202_205_304_d2;
global g_decGl_doxy_202_205_304_d3;
global g_decGl_doxy_202_205_304_sPreset;
global g_decGl_doxy_202_205_304_b0;
global g_decGl_doxy_202_205_304_b1;
global g_decGl_doxy_202_205_304_b2;
global g_decGl_doxy_202_205_304_b3;
global g_decGl_doxy_202_205_304_c0;
global g_decGl_doxy_202_205_304_pCoef1;
global g_decGl_doxy_202_205_304_pCoef2;
global g_decGl_doxy_202_205_304_pCoef3;

global g_decGl_doxy_202_204_304_d0;
global g_decGl_doxy_202_204_304_d1;
global g_decGl_doxy_202_204_304_d2;
global g_decGl_doxy_202_204_304_d3;
global g_decGl_doxy_202_204_304_sPreset;
global g_decGl_doxy_202_204_304_b0;
global g_decGl_doxy_202_204_304_b1;
global g_decGl_doxy_202_204_304_b2;
global g_decGl_doxy_202_204_304_b3;
global g_decGl_doxy_202_204_304_c0;
global g_decGl_doxy_202_204_304_pCoef1;
global g_decGl_doxy_202_204_304_pCoef2;
global g_decGl_doxy_202_204_304_pCoef3;

global g_decGl_doxy_102_207_206_a0;
global g_decGl_doxy_102_207_206_a1;
global g_decGl_doxy_102_207_206_a2;
global g_decGl_doxy_102_207_206_a3;
global g_decGl_doxy_102_207_206_a4;
global g_decGl_doxy_102_207_206_a5;
global g_decGl_doxy_102_207_206_b0;
global g_decGl_doxy_102_207_206_b1;
global g_decGl_doxy_102_207_206_b2;
global g_decGl_doxy_102_207_206_b3;
global g_decGl_doxy_102_207_206_c0;

% Matlab version (before or after R2017A)
global g_decGl_matlabVersionBeforeR2017A;
if (verLessThan('matlab', '9.2')) % R2017A
   g_decGl_matlabVersionBeforeR2017A = 1;
else
   g_decGl_matlabVersionBeforeR2017A = 0;
end

% global default values initialization
g_decGl_dateDef = 99999.99999999;
g_decGl_epochDateDef = 9999999999.0;
g_decGl_argosLonDef = 999.999;
g_decGl_argosLatDef = 99.999;
g_decGl_ncDateDef = 999999;
g_decGl_ncArgosLonDef = 99999;
g_decGl_ncArgosLatDef = 99999;

% PHASE codes
g_decGl_phaseSurfDrift = 0;
g_decGl_phaseDescent = 1;
g_decGl_phaseSubSurfDrift = 2;
g_decGl_phaseInflexion = 3;
g_decGl_phaseAscent = 4;
g_decGl_phaseGrounded = 5;
g_decGl_phaseInconsistant = 6;
g_decGl_phaseDefault = -128;

% the first 3 digits are incremented at each new complete dated release
% the last digit is incremented at each patch associated to a given complete
% dated release 
g_decGl_decoderVersion = '011k';

% QC flag values
g_decGl_qcDef = int8(-128);
g_decGl_qcNoQc = int8(0);
g_decGl_qcGood = int8(1);
g_decGl_qcProbablyGood = int8(2);
g_decGl_qcCorrectable = int8(3);
g_decGl_qcBad = int8(4);
g_decGl_qcChanged = int8(5);
g_decGl_qcInterpolated = int8(8);
g_decGl_qcMissing = int8(9);

% QC flag values (char)
g_decGl_qcStrDef = ' ';
g_decGl_qcStrNoQc = '0';
g_decGl_qcStrGood = '1';
g_decGl_qcStrProbablyGood = '2';
g_decGl_qcStrCorrectable = '3';
g_decGl_qcStrBad = '4';
g_decGl_qcStrChanged = '5';
g_decGl_qcStrUnused1 = '6';
g_decGl_qcStrUnused2 = '7';
g_decGl_qcStrInterpolated = '8';
g_decGl_qcStrMissing = '9';

g_decGl_janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
g_decGl_janFirst200InEpoch = gl_julian_2_epoch(datenum('2000-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS')-g_decGl_janFirst1950InMatlab);

% DOXY coefficients
g_decGl_doxy_201and202_201_301_d0 = 24.4543;
g_decGl_doxy_201and202_201_301_d1 = -67.4509;
g_decGl_doxy_201and202_201_301_d2 = -4.8489;
g_decGl_doxy_201and202_201_301_d3 = -5.44e-4;
g_decGl_doxy_201and202_201_301_sPreset = 0;
g_decGl_doxy_201and202_201_301_b0 = -6.24523e-3;
g_decGl_doxy_201and202_201_301_b1 = -7.37614e-3;
g_decGl_doxy_201and202_201_301_b2 = -1.03410e-2;
g_decGl_doxy_201and202_201_301_b3 = -8.17083e-3;
g_decGl_doxy_201and202_201_301_c0 = -4.88682e-7;
g_decGl_doxy_201and202_201_301_pCoef2 = 0.00025;
g_decGl_doxy_201and202_201_301_pCoef3 = 0.0328;

g_decGl_doxy_201_202_202_d0 = 24.4543;
g_decGl_doxy_201_202_202_d1 = -67.4509;
g_decGl_doxy_201_202_202_d2 = -4.8489;
g_decGl_doxy_201_202_202_d3 = -5.44e-4;
g_decGl_doxy_201_202_202_sPreset = 0;
g_decGl_doxy_201_202_202_b0 = -6.24523e-3;
g_decGl_doxy_201_202_202_b1 = -7.37614e-3;
g_decGl_doxy_201_202_202_b2 = -1.03410e-2;
g_decGl_doxy_201_202_202_b3 = -8.17083e-3;
g_decGl_doxy_201_202_202_c0 = -4.88682e-7;
g_decGl_doxy_201_202_202_pCoef1 = 0.1;
g_decGl_doxy_201_202_202_pCoef2 = 0.00022;
g_decGl_doxy_201_202_202_pCoef3 = 0.0419;

g_decGl_doxy_202_205_302_a0 = 2.00856;
g_decGl_doxy_202_205_302_a1 = 3.22400;
g_decGl_doxy_202_205_302_a2 = 3.99063;
g_decGl_doxy_202_205_302_a3 = 4.80299;
g_decGl_doxy_202_205_302_a4 = 9.78188e-1;
g_decGl_doxy_202_205_302_a5 = 1.71069;
g_decGl_doxy_202_205_302_d0 = 24.4543;
g_decGl_doxy_202_205_302_d1 = -67.4509;
g_decGl_doxy_202_205_302_d2 = -4.8489;
g_decGl_doxy_202_205_302_d3 = -5.44e-4;
g_decGl_doxy_202_205_302_sPreset = 0;
g_decGl_doxy_202_205_302_b0 = -6.24523e-3;
g_decGl_doxy_202_205_302_b1 = -7.37614e-3;
g_decGl_doxy_202_205_302_b2 = -1.03410e-2;
g_decGl_doxy_202_205_302_b3 = -8.17083e-3;
g_decGl_doxy_202_205_302_c0 = -4.88682e-7;
g_decGl_doxy_202_205_302_pCoef1 = 0.1;
g_decGl_doxy_202_205_302_pCoef2 = 0.00022;
g_decGl_doxy_202_205_302_pCoef3 = 0.0419;

g_decGl_doxy_202_205_303_a0 = 2.00856;
g_decGl_doxy_202_205_303_a1 = 3.22400;
g_decGl_doxy_202_205_303_a2 = 3.99063;
g_decGl_doxy_202_205_303_a3 = 4.80299;
g_decGl_doxy_202_205_303_a4 = 9.78188e-1;
g_decGl_doxy_202_205_303_a5 = 1.71069;
g_decGl_doxy_202_205_303_d0 = 24.4543;
g_decGl_doxy_202_205_303_d1 = -67.4509;
g_decGl_doxy_202_205_303_d2 = -4.8489;
g_decGl_doxy_202_205_303_d3 = -5.44e-4;
g_decGl_doxy_202_205_303_sPreset = 0;
g_decGl_doxy_202_205_303_b0 = -6.24523e-3;
g_decGl_doxy_202_205_303_b1 = -7.37614e-3;
g_decGl_doxy_202_205_303_b2 = -1.03410e-2;
g_decGl_doxy_202_205_303_b3 = -8.17083e-3;
g_decGl_doxy_202_205_303_c0 = -4.88682e-7;
g_decGl_doxy_202_205_303_pCoef1 = 0.1;
g_decGl_doxy_202_205_303_pCoef2 = 0.00022;
g_decGl_doxy_202_205_303_pCoef3 = 0.0419;

g_decGl_doxy_202_205_304_d0 = 24.4543;
g_decGl_doxy_202_205_304_d1 = -67.4509;
g_decGl_doxy_202_205_304_d2 = -4.8489;
g_decGl_doxy_202_205_304_d3 = -5.44e-4;
g_decGl_doxy_202_205_304_sPreset = 0;
g_decGl_doxy_202_205_304_b0 = -6.24523e-3;
g_decGl_doxy_202_205_304_b1 = -7.37614e-3;
g_decGl_doxy_202_205_304_b2 = -1.03410e-2;
g_decGl_doxy_202_205_304_b3 = -8.17083e-3;
g_decGl_doxy_202_205_304_c0 = -4.88682e-7;
g_decGl_doxy_202_205_304_pCoef1 = 0.1;
g_decGl_doxy_202_205_304_pCoef2 = 0.00022;
g_decGl_doxy_202_205_304_pCoef3 = 0.0419;

g_decGl_doxy_202_204_304_d0 = 24.4543;
g_decGl_doxy_202_204_304_d1 = -67.4509;
g_decGl_doxy_202_204_304_d2 = -4.8489;
g_decGl_doxy_202_204_304_d3 = -5.44e-4;
g_decGl_doxy_202_204_304_sPreset = 0;
g_decGl_doxy_202_204_304_b0 = -6.24523e-3;
g_decGl_doxy_202_204_304_b1 = -7.37614e-3;
g_decGl_doxy_202_204_304_b2 = -1.03410e-2;
g_decGl_doxy_202_204_304_b3 = -8.17083e-3;
g_decGl_doxy_202_204_304_c0 = -4.88682e-7;
g_decGl_doxy_202_204_304_pCoef1 = 0.1;
g_decGl_doxy_202_204_304_pCoef2 = 0.00022;
g_decGl_doxy_202_204_304_pCoef3 = 0.0419;

g_decGl_doxy_102_207_206_a0 = 2.00907;
g_decGl_doxy_102_207_206_a1 = 3.22014;
g_decGl_doxy_102_207_206_a2 = 4.0501;
g_decGl_doxy_102_207_206_a3 = 4.94457;
g_decGl_doxy_102_207_206_a4 = -0.256847;
g_decGl_doxy_102_207_206_a5 = 3.88767;
g_decGl_doxy_102_207_206_b0 = -0.00624523;
g_decGl_doxy_102_207_206_b1 = -0.00737614;
g_decGl_doxy_102_207_206_b2 = -0.00103410;    
g_decGl_doxy_102_207_206_b3 = -0.00817083;
g_decGl_doxy_102_207_206_c0 = -0.000000488682;

return

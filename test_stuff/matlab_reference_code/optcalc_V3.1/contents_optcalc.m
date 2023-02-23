%{
Contents optcalc V2.0

conversion of different oxygen variables:
molal2molar    -    convert from molal unit x/kg to molar unit x/l
molar2molal    -    convert from molar unit x/l to molal unit x/kg

O2conctoO2sat  -    O2 concentration / umol/l to O2 saturation / %
O2conctopO2    -    O2 concentration / umol/l to O2 partial pressure / mbar
O2sattoO2conc  -    O2 saturation / % to O2 concentration / umol/l
O2sattopO2     -    O2 saturation / % to O2 partial pressure / mbar
pO2toO2conc    -    O2 partial pressure / mbar to O2 concentration / umol/l
pO2toO2sat     -    O2 partial pressure / mbar to O2 saturation / %
                    all with Salinity and atm. pressure correction
O2solubility   -    calculates oxygen solubilty / umol/l at T, S (Garcia & Gordon 1992)
O2solubility_molal - calculates oxygen solubilty / umol/kg at T, S (Garcia & Gordon 1992)

calculation of (calibrated) optode data
optcalcO2      -    apply individual foil coefficients according to the specified 
                    model (Phase, Temperature -> O2 concentration / umol/l);
                    includes salinity and temperature compensation for each specified model;
                    option to use revised hydrostatic pressure correction scheme (subm. ...)
                    or "traditional" linear, constant O2 factor

calibration routines
optfitfoilcoef              -  fit foil coefficients according to the specified model
                               (Phase, Temperature -> O2); 
                               option to use the same specified model to produce 
                               O2 concentration / umol/l or O2 partial pressure / mbar
optfitfoilcoeffromstruct    -  wrapper function to optfitfoilcoef to ease the usage; 
                               to be used with calibration structures with respective 
                               fields t, bp, OW, ...
optfoilcoef_modelAtomodelB.m - convert one functional model coefficients to another 
                               set of model coefficients
aanderaarefitoldcalibrationcertificate - refit Aanderaa factory batch calibration sheet 
                               to the specified model
aanderaarefitnewcalibrationcertificate - refit (new) Aanderaa factory calibration sheet 
                               to the specified model (~pre factory multipoint calibration era)

optode model functions (kind of equation used for O2 calculation)
optodefun3830       -    Aanderaa *DPhase*->O2conc calculation (20 coefficients); square matrix in T & Phase (4x5)
optodefun3x4b       -    Craig Neill BPhase->pO2 calculation (14 coefficients); upper polynomial matrix in T & Phase
optodefun5x5b       -    Craig Neill BPhase->pO2 calculation (21 coefficients); function used in 4330 optodes; upper polynomial matrix in T & Phase
polyfitweighted2, polyval2 - used for BPhase->pO2 calculation with mixed 
                             coefficients up to degree n in Phase and T

optodefunUchida     -    Stern-Volmer inspired BPhase->pO2 calculation (7 coefficients); 
                         original Uchida et al. 2008 equation;
                         options for optfitfoilcoef.m / optcalcO2.m:
                         'uchidaAADI' > exact Uchida et al. 2008 variant on O2conc, used in AADI multipoint calibrated optodes
                         'uchida'     > Bittig et al. 2012 variant to give pO2 instead
optodefunUchidaSBE  -    Stern-Volmer inspired BPhase->pO2 calculation (8 coefficients); 
                         modification with squared term used in SBE63 optodes
                         'uchidaSBE'  > gives pO2; 'uchidaSBEmolar'   > gives O2conc
optodefunUchidasq   -    Stern-Volmer inspired BPhase->pO2 calculation (7 coefficients); 
                         modification with squared term (GEOMAR)
                         'uchidasq'   > gives pO2; 'uchidasqmolar'    > gives O2conc
optodefunUchidasimple -  Stern-Volmer inspired BPhase->pO2 calculation (6 coefficients); 
                         Uchida et al. 2010 equation; (simplification of Uchida et al. 2008)
                         'uchidasimple'> gives pO2; 'uchidasimplemolar'> gives O2conc
optodefunMcNeil       -  Stern-Volmer two-site inspired BPhase->pO2 calculation (6 coefficients);
                         McNeil & d'Asaro 2014 equation
                    !!! make sure to use the correct modulation frequency for your sensor !!!
                    !!! 5000 Hz for Aanderaa optodes, 3840 Hz for Sea-Bird SBE63 optodes  !!!
                    !!! (change in code l. 25/26)                                         !!!

auxiliary m-files (used for variable conversion)
O2freshtosal   -    apply salinity correction to O2 concentration / umol/l
O2saltofresh   -    revert salinity correction to get freshwater O2 concentration / umol/l
optbphasetodphase - convert BPhase to DPhase / TCPhase to CalPhase 
optprescorr    -    (hydrostatic) pressure correction to optode sensor readings using linear O2 factor
optreverseprescorr- revert (hydrostatic) pressure correction of optode sensor readings using linear O2 factor
scaledT        -    calculate scaled temperature
watervapor     -    calculate pH2O / atm after Weiss and Price 1980
volts2bphase   -    analog output of AADI 3966 D/A Converter to BPhase


Henry Bittig, GEOMAR
26.06.2015
%}
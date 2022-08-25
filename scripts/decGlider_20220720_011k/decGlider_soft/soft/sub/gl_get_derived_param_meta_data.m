% ------------------------------------------------------------------------------
% Retrieve specified meta-data(derivation_equation, derivation_coefficient
% and derivation_comment) for derived parameters.
%
% SYNTAX :
%  [o_metaData] = gl_get_derived_param_meta_data(a_paramName, a_info)
%
% INPUT PARAMETERS :
%   a_paramName : name of the derived parameter
%   a_info : additional information (DOXY processing case name)
%
% OUTPUT PARAMETERS :
%   o_metaData : corresponding meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/06/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = gl_get_derived_param_meta_data(a_paramName, a_info)

% output parameters initialization
o_metaData = [];

% arrays to store calibration information
global g_decGl_calibInfo;
global g_decGl_calibInfoId;

% retrieve global coefficient default values
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

switch (a_paramName)
   
   case 'BBP700'
      
      % get calibration information
      if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
         return
      else
         calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
         if ((isfield(calibInfo, 'ScaleFactBBP700')) && ...
               (isfield(calibInfo, 'DarkCountBBP700')) && ...
               (isfield(calibInfo, 'KhiCoefBBP700')) && ...
               (isfield(calibInfo, 'MeasAngleBBP700')))
            scaleFactBBP700 = double(calibInfo.ScaleFactBBP700);
            darkCountBBP700 = double(calibInfo.DarkCountBBP700);
            khiCoefBBP700 = double(calibInfo.KhiCoefBBP700);
            measAngleBBP700 = double(calibInfo.MeasAngleBBP700);
         else
            return
         end
      end

      o_metaData.derivation_equation = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700)*SCALE_BACKSCATTERING700-BETASW700)';
      o_metaData.derivation_coefficient = sprintf('DARK_BACKSCATTERING700=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at %d angularDeg', ...
         darkCountBBP700, scaleFactBBP700, khiCoefBBP700, measAngleBBP700);
      o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis. Ref: Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916. Reprocessed from the file provided by Andrew Bernard (Seabird) following ADMT18. This file is accessible at http://doi.org/10.17882/54520.';
      
   case 'BBP470'
      
      % get calibration information
      if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
         return
      else
         calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
         if ((isfield(calibInfo, 'ScaleFactBBP470')) && ...
               (isfield(calibInfo, 'DarkCountBBP470')) && ...
               (isfield(calibInfo, 'KhiCoefBBP470')) && ...
               (isfield(calibInfo, 'MeasAngleBBP470')))
            scaleFactBBP470 = double(calibInfo.ScaleFactBBP470);
            darkCountBBP470 = double(calibInfo.DarkCountBBP470);
            khiCoefBBP470 = double(calibInfo.KhiCoefBBP470);
            measAngleBBP470 = double(calibInfo.MeasAngleBBP470);
         else
            return
         end
      end

      o_metaData.derivation_equation = 'BBP470=2*pi*khi*((BETA_BACKSCATTERING470-DARK_BACKSCATTERING470)*SCALE_BACKSCATTERING470-BETASW470)';
      o_metaData.derivation_coefficient = sprintf('DARK_BACKSCATTERING470=%g, SCALE_BACKSCATTERING470=%g, khi=%g, BETASW470 (contribution of pure sea water) is calculated at %d angularDeg', ...
         darkCountBBP470, scaleFactBBP470, khiCoefBBP470, measAngleBBP470);
      o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis. Ref: Sullivan et al., 2012, Zhang et al., 2009, BETASW470 is the contribution by the pure seawater at 470nm, the calculation can be found at http://doi.org/10.17882/42916. Reprocessed from the file provided by Andrew Bernard (Seabird) following ADMT18. This file is accessible at http://doi.org/10.17882/54520.';
      
   case 'CDOM'
      
      % get calibration information
      if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
         return
      else
         calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
         if ((isfield(calibInfo, 'ScaleFactCDOM')) && ...
               (isfield(calibInfo, 'DarkCountCDOM')))
            scaleFactCDOM = double(calibInfo.ScaleFactCDOM);
            darkCountCDOM = double(calibInfo.DarkCountCDOM);
         else
            return
         end
      end
      
      o_metaData.derivation_equation = 'CDOM=(FLUORESCENCE_CDOM-DARK_CDOM)*SCALE_CDOM';
      o_metaData.derivation_coefficient = sprintf('SCALE_CDOM=%g, DARK_CDOM=%g', ...
         scaleFactCDOM, darkCountCDOM);
      o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis.';
      
   case 'CHLA'
      
      % get calibration information
      if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
         return
      else
         calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
         if ((isfield(calibInfo, 'ScaleFactCHLA')) && ...
               (isfield(calibInfo, 'DarkCountCHLA')))
            scaleFactCHLA = double(calibInfo.ScaleFactCHLA);
            darkCountCHLA = double(calibInfo.DarkCountCHLA);
         else
            return
         end
      end
      
      o_metaData.derivation_equation = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA)*SCALE_CHLA';
      o_metaData.derivation_coefficient = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g', ...
         scaleFactCHLA, darkCountCHLA);
      o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis.';   
   
   case 'DOXY'
      
      switch (a_info)
         
         case '201_201_301'
            
            % get calibration information
            if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
               doxyCalibRefSalinity = 0;
            else
               calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
               if (isfield(calibInfo, 'DoxyCalibRefSalinity'))
                  doxyCalibRefSalinity = calibInfo.DoxyCalibRefSalinity;
               else
                  doxyCalibRefSalinity = 0;
               end
            end
            
            o_metaData.derivation_equation = 'O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[(PSAL-Sref)*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*(PSAL^2-Sref^2)]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho; where rho is the potential density [kg/L] calculated from CTD data';
            o_metaData.derivation_coefficient = sprintf('Sref=%g; Spreset=%g; Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               doxyCalibRefSalinity, ...
               g_decGl_doxy_201and202_201_301_sPreset, ...
               g_decGl_doxy_201and202_201_301_pCoef2, ...
               g_decGl_doxy_201and202_201_301_pCoef3, ...
               g_decGl_doxy_201and202_201_301_b0, ...
               g_decGl_doxy_201and202_201_301_b1, ...
               g_decGl_doxy_201and202_201_301_b2, ...
               g_decGl_doxy_201and202_201_301_b3, ...
               g_decGl_doxy_201and202_201_301_c0, ...
               g_decGl_doxy_201and202_201_301_d0, ...
               g_decGl_doxy_201and202_201_301_d1, ...
               g_decGl_doxy_201and202_201_301_d2, ...
               g_decGl_doxy_201and202_201_301_d3 ...
               );
            o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis. Ref: see TD218 operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case '202_201_301'
            
            % get calibration information
            if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
               doxyCalibRefSalinity = 0;
            else
               calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
               if (isfield(calibInfo, 'DoxyCalibRefSalinity'))
                  doxyCalibRefSalinity = calibInfo.DoxyCalibRefSalinity;
               else
                  doxyCalibRefSalinity = 0;
               end
            end
            
            o_metaData.derivation_equation = 'O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[(PSAL-Sref)*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*(PSAL^2-Sref^2)]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho; where rho is the potential density [kg/L] calculated from CTD data';
            o_metaData.derivation_coefficient = sprintf('Sref=%g; Spreset=%g; Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               doxyCalibRefSalinity, ...
               g_decGl_doxy_201and202_201_301_sPreset, ...
               g_decGl_doxy_201and202_201_301_pCoef2, ...
               g_decGl_doxy_201and202_201_301_pCoef3, ...
               g_decGl_doxy_201and202_201_301_b0, ...
               g_decGl_doxy_201and202_201_301_b1, ...
               g_decGl_doxy_201and202_201_301_b2, ...
               g_decGl_doxy_201and202_201_301_b3, ...
               g_decGl_doxy_201and202_201_301_c0, ...
               g_decGl_doxy_201and202_201_301_d0, ...
               g_decGl_doxy_201and202_201_301_d1, ...
               g_decGl_doxy_201and202_201_301_d2, ...
               g_decGl_doxy_201and202_201_301_d3 ...
               );
            o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis. Ref: see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case '201_202_202'
            
            % get calibration information
            if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
               fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
               return
            end
            calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
            if (~isfield(calibInfo, 'TabPhaseCoef') || ~isfield(calibInfo, 'TabDoxyCoef'))
               fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
               return
            end
            tabPhaseCoef = calibInfo.TabPhaseCoef;
            % the size of the tabPhaseCoef should be: size(tabPhaseCoef) = 1 4 for the
            % Aanderaa standard calibration (tabPhaseCoef(i) = PhaseCoefi).
            if (~isempty(find((size(tabPhaseCoef) == [1 4]) ~= 1, 1)))
               fprintf('ERROR: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n');
               return
            end
            tabDoxyCoef = calibInfo.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
            % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
            if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
               fprintf('ERROR: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n');
               return
            end
            
            o_metaData.derivation_equation = 'UNCAL_Phase=BPHASE_DOXY-RPHASE_DOXY; Phase_Pcorr=UNCAL_Phase+Pcoef1*PRES/1000; DPHASE_DOXY=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Pcorr_Phase^2+PhaseCoef3*Pcorr_Phase^3; MOLAR_DOXY=c0+c1*DPHASE_DOXY+c2*DPHASE_DOXY^2+c3*DPHASE_DOXY^3+c4*DPHASE_DOXY^4; ci=ci0+ci1*TEMP+ci2*TEMP^2+ci3*TEMP^3, i=0..4; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_metaData.derivation_coefficient = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c00=%g, c01=%g, c02=%g, c03=%g, c10=%g, c11=%g, c12=%g, c13=%g, c20=%g, c21=%g, c22=%g, c23=%g, c30=%g, c31=%g, c32=%g, c33=%g, c40=%g, c41=%g, c42=%g, c43=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decGl_doxy_201_202_202_sPreset, ...
               g_decGl_doxy_201_202_202_pCoef1, ...
               g_decGl_doxy_201_202_202_pCoef2, ...
               g_decGl_doxy_201_202_202_pCoef3, ...
               g_decGl_doxy_201_202_202_b0, ...
               g_decGl_doxy_201_202_202_b1, ...
               g_decGl_doxy_201_202_202_b2, ...
               g_decGl_doxy_201_202_202_b3, ...
               g_decGl_doxy_201_202_202_c0, ...
               tabPhaseCoef(1, 1:4), ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:4), ...
               tabDoxyCoef(3, 1:4), ...
               tabDoxyCoef(4, 1:4), ...
               tabDoxyCoef(5, 1:4), ...
               g_decGl_doxy_201_202_202_d0, ...
               g_decGl_doxy_201_202_202_d1, ...
               g_decGl_doxy_201_202_202_d2, ...
               g_decGl_doxy_201_202_202_d3 ...
               );
            o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis. Ref: see TD218 operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case '202_205_302'
            
            % get calibration information
            if (isempty(g_decGl_calibInfo) || ...
                  ~isfield(g_decGl_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decGl_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
               return
            end
            tabDoxyCoef = g_decGl_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 28 for the
            % Aanderaa standard calibration
            if (~isempty(find((size(tabDoxyCoef) == [5 28]) ~= 1, 1)))
               fprintf('ERROR: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n');
               return
            end
            
            o_metaData.derivation_equation = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP_DOXY^m0*CalPhase^n0+c1*TEMP_DOXY^m1*CalPhase^n1+..+c27*TEMP_DOXY^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP_DOXY+273.15)-4.681*ln(TEMP_DOXY+273.15)])*0.20946]; MOLAR_DOXY=Cstar*44.614*AirSat/100; ln(Cstar)=A0+A1*Ts1+A2*Ts1^2+A3*Ts1^3+A4*Ts1^4+A5*Ts1^5; Ts1=ln[(298.15-TEMP_DOXY)/(273.15+TEMP_DOXY)]; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts2+B2*Ts2^2+B3*Ts2^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Ts2=ln[(298.15-TEMP)/(273.15+TEMP)]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_metaData.derivation_coefficient = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decGl_doxy_202_205_302_sPreset, ...
               g_decGl_doxy_202_205_302_pCoef1, ...
               g_decGl_doxy_202_205_302_pCoef2, ...
               g_decGl_doxy_202_205_302_pCoef3, ...
               g_decGl_doxy_202_205_302_b0, ...
               g_decGl_doxy_202_205_302_b1, ...
               g_decGl_doxy_202_205_302_b2, ...
               g_decGl_doxy_202_205_302_b3, ...
               g_decGl_doxy_202_205_302_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               g_decGl_doxy_202_205_302_a0, ...
               g_decGl_doxy_202_205_302_a1, ...
               g_decGl_doxy_202_205_302_a2, ...
               g_decGl_doxy_202_205_302_a3, ...
               g_decGl_doxy_202_205_302_a4, ...
               g_decGl_doxy_202_205_302_a5, ...
               g_decGl_doxy_202_205_302_d0, ...
               g_decGl_doxy_202_205_302_d1, ...
               g_decGl_doxy_202_205_302_d2, ...
               g_decGl_doxy_202_205_302_d3 ...
               );
            o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis. Ref: see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case '202_205_303'
            
            % get calibration information
            if (isempty(g_decGl_calibInfo) || ...
                  ~isfield(g_decGl_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decGl_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
               return
            end
            tabDoxyCoef = g_decGl_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
            % Aanderaa standard calibration + an additional two-point adjustment
            if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
               fprintf('ERROR: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n');
               return
            end
            
            o_metaData.derivation_equation = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP^m0*CalPhase^n0+c1*TEMP^m1*CalPhase^n1+..+c27*TEMP^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP+273.15)-4.681*ln(TEMP+273.15)])*0.20946]; MOLAR_DOXY=Cstar*44.614*AirSat/100; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; MOLAR_DOXY=ConcCoef0+ConcCoef1*MOLAR_DOXY; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_metaData.derivation_coefficient = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; ConcCoef0=%g, ConcCoef1=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decGl_doxy_202_205_303_sPreset, ...
               g_decGl_doxy_202_205_303_pCoef1, ...
               g_decGl_doxy_202_205_303_pCoef2, ...
               g_decGl_doxy_202_205_303_pCoef3, ...
               g_decGl_doxy_202_205_303_b0, ...
               g_decGl_doxy_202_205_303_b1, ...
               g_decGl_doxy_202_205_303_b2, ...
               g_decGl_doxy_202_205_303_b3, ...
               g_decGl_doxy_202_205_303_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               tabDoxyCoef(6, 1:2), ...
               g_decGl_doxy_202_205_303_a0, ...
               g_decGl_doxy_202_205_303_a1, ...
               g_decGl_doxy_202_205_303_a2, ...
               g_decGl_doxy_202_205_303_a3, ...
               g_decGl_doxy_202_205_303_a4, ...
               g_decGl_doxy_202_205_303_a5, ...
               g_decGl_doxy_202_205_303_d0, ...
               g_decGl_doxy_202_205_303_d1, ...
               g_decGl_doxy_202_205_303_d2, ...
               g_decGl_doxy_202_205_303_d3 ...
               );
            o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis. Ref: see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case '202_205_304'
            
            % get calibration information
            if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
               fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
               return
            end
            calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
            if (~isfield(calibInfo, 'TabDoxyCoef'))
               fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
               return
            end
            tabDoxyCoef = calibInfo.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7 for the
            % Aanderaa Stern-Volmer equation
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n');
               return
            end

            o_metaData.derivation_equation = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; MOLAR_DOXY=[((c3+c4*TEMP_DOXY)/(c5+c6*CalPhase))-1]/Ksv; Ksv=c0+c1*TEMP_DOXY+c2*TEMP_DOXY^2; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_metaData.derivation_coefficient = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decGl_doxy_202_205_304_sPreset, ...
               g_decGl_doxy_202_205_304_pCoef1, ...
               g_decGl_doxy_202_205_304_pCoef2, ...
               g_decGl_doxy_202_205_304_pCoef3, ...
               g_decGl_doxy_202_205_304_b0, ...
               g_decGl_doxy_202_205_304_b1, ...
               g_decGl_doxy_202_205_304_b2, ...
               g_decGl_doxy_202_205_304_b3, ...
               g_decGl_doxy_202_205_304_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:7), ...
               g_decGl_doxy_202_205_304_d0, ...
               g_decGl_doxy_202_205_304_d1, ...
               g_decGl_doxy_202_205_304_d2, ...
               g_decGl_doxy_202_205_304_d3 ...
               );
            o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis. Ref: see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';

         case '202_204_304'
            
            % get calibration information
            if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
               fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
               return
            end
            calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
            if (~isfield(calibInfo, 'TabDoxyCoef'))
               fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
               return
            end
            tabDoxyCoef = calibInfo.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7 for the
            % Aanderaa Stern-Volmer equation
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n');
               return
            end

            o_metaData.derivation_equation = 'Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; MOLAR_DOXY=[((c3+c4*TEMP_DOXY)/(c5+c6*CalPhase))-1]/Ksv; Ksv=c0+c1*TEMP_DOXY+c2*TEMP_DOXY^2; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_metaData.derivation_coefficient = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decGl_doxy_202_204_304_sPreset, ...
               g_decGl_doxy_202_204_304_pCoef1, ...
               g_decGl_doxy_202_204_304_pCoef2, ...
               g_decGl_doxy_202_204_304_pCoef3, ...
               g_decGl_doxy_202_204_304_b0, ...
               g_decGl_doxy_202_204_304_b1, ...
               g_decGl_doxy_202_204_304_b2, ...
               g_decGl_doxy_202_204_304_b3, ...
               g_decGl_doxy_202_204_304_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:7), ...
               g_decGl_doxy_202_204_304_d0, ...
               g_decGl_doxy_202_204_304_d1, ...
               g_decGl_doxy_202_204_304_d2, ...
               g_decGl_doxy_202_204_304_d3 ...
               );
            o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis. Ref: see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';

         case '102_207_206'
            
            % get calibration information
            if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
               fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
               return
            end
            calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
            if (~isfield(calibInfo, 'SbeTabDoxyCoef'))
               fprintf('WARNING: DOXY calibration coefficients are missing => DOXY data set to fill value\n');
               return
            end
            tabDoxyCoef = calibInfo.SbeTabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 6
            if (~isempty(find((size(tabDoxyCoef) == [1 6]) ~= 1, 1)))
               fprintf('ERROR: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n');
               return
            end

            o_metaData.derivation_equation = 'Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; Oxsol=exp[A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5+PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; MLPL_DOXY=Soc*(FREQUENCY_DOXY+Foffset)*Oxsol*(1.0+A*TEMP+B*TEMP^2+C*TEMP^3)*exp[E*PRES/(273.15+TEMP)]; DOXY=44.6596*MLPL_DOXY/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_metaData.derivation_coefficient = sprintf('Soc=%g, Foffset=%g, A=%g, B=%g, C=%g, E=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g', ...
               tabDoxyCoef(1:6), ...
               g_decGl_doxy_102_207_206_a0, ...
               g_decGl_doxy_102_207_206_a1, ...
               g_decGl_doxy_102_207_206_a2, ...
               g_decGl_doxy_102_207_206_a3, ...
               g_decGl_doxy_102_207_206_a4, ...
               g_decGl_doxy_102_207_206_a5, ...
               g_decGl_doxy_102_207_206_b0, ...
               g_decGl_doxy_102_207_206_b1, ...
               g_decGl_doxy_102_207_206_b2, ...
               g_decGl_doxy_102_207_206_b3, ...
               g_decGl_doxy_102_207_206_c0);
            o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis. Ref: see Application note #64: SBE43 Dissolved Oxygen Sensor – Background Information, Deployment Recommendations and Clearing and Storage (revised June 2013); see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         otherwise
            fprintf('WARNING: nothing implemented yet for DOXY meta-data for case %s\n', ...
               a_info);
            
      end
      
   case 'NITRATE'
      
      o_metaData.derivation_equation = 'NITRATE=MOLAR_NITRATE/rho; where rho is the potential density [kg/L] calculated from CTD data';
      o_metaData.derivation_coefficient = '';
      o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis.';
      
   case {'PSAL', 'PSAL2'}
      
      o_metaData.derivation_equation = 'T=TEMP*1.00024 (IPST90 to IPTS68 TEMP conversion); RTEMP=((((C4*T)+C3)*T+C2)*T+C1)*T+C0; P=PRES; CXP=(((E3*P)+E2)*P+E1)*P; C=CNDC; R=C/CNO68; AXT=(D4*T+D3)*R; BXT=((D2*T)+D1)*T+1.; RP=CXP/(AXT+BXT)+1.; RT=R/(RP*RTEMP); DS=(T-15.)/((T-15.)*0.0162+1.); S=(B5*DS+A5)*RT^2.5+(B4*DS+A4)*RT*RT+(B3*DS+A3)*RT^1.5; PSAL=S+(B2*DS+A2)*RT+(B1*DS+A1)*RT^.5+(B0*DS+A0)';
      o_metaData.derivation_coefficient = 'CNO68=42.914; C0=0.6766097, C1=2.00564e-2, C2=1.104259e-4, C3=-6.9698e-7, C4=1.0031e-9; E1=2.07e-5, E2=-6.37e-10, E3=3.989e-15; D1=3.426e-2, D2=4.464e-4, D3=4.215e-1, D4=-3.107e-3; A0=0.008, A1=-0.1692, A2=25.3851, A3=14.0941, A4=-7.0261, A5=2.7081; B0=0.0005, B1=-0.0056, B2=-0.0066, B3=-0.0375, B4=0.0636, B5=-0.0144';
      o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis. Ref: PRACTICAL SALINITY SCALE 1978: E.L. LEWIS - R.G. PERKIN DEEP-SEA RESEARCH, VOL. 28A, N0 4, PP. 307-328, 1981; COMPLIANT WITH THE WORKING DRAFT OF S.C.O.R. (WG51); C(35.15.0)=CNO68=42.914 DEEP-SEA RESEARCH, VOL. 23, PP.157-165, 1976.';

   case 'TURBIDITY'
      
      % get calibration information
      if (isempty(g_decGl_calibInfo) || (length(g_decGl_calibInfo) < g_decGl_calibInfoId))
         return
      else
         calibInfo = g_decGl_calibInfo{g_decGl_calibInfoId};
         if ((isfield(calibInfo, 'ScaleFactTURBIDITY')) && ...
               (isfield(calibInfo, 'DarkCountTURBIDITY')))
            scaleFactTURBIDITY = double(calibInfo.ScaleFactTURBIDITY);
            darkCountTURBIDITY = double(calibInfo.DarkCountTURBIDITY);
         else
            return
         end
      end
      
      o_metaData.derivation_equation = 'TURBIDITY=(SIDE_SCATTERING_TURBIDITY-DARK_TURBIDITY)*SCALE_TURBIDITY';
      o_metaData.derivation_coefficient = sprintf('SCALE_TURBIDITY=%g, DARK_TURBIDITY=%g', ...
         scaleFactTURBIDITY, darkCountTURBIDITY);
      o_metaData.derivation_comment = 'Not measured by the glider. Calculated by Coriolis.';

   otherwise
      fprintf('WARNING: nothing implemented yet for %s meta-data\n', ...
         a_paramName);
      
end

return

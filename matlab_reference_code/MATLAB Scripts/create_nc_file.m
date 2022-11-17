function create_nc_file(dat,options)

    ncfname = options.ncfname;
    x_dim = length(dat.time_ctd);

    svu_dim = length(dat.oxy_SVU_foil_coef);
    
    system(['rm ',ncfname])

    %% NAV

    
    
    nccreate(ncfname,'time','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'time', 'long_name', 'glider merged time');
    ncwriteatt(ncfname, 'time', 'units', '(MATLAB Serial Date) days since 0000-01-01 00:00:00');
    ncwriteatt(ncfname, 'time', '_CoordinateAxisType', 'time');

    nccreate(ncfname,'time_unix','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'time_unix', 'long_name', 'glider merged epoch time');
    ncwriteatt(ncfname, 'time_unix', 'units', 'seconds since 1970-01-01 00:00:00');

    nccreate(ncfname,'time_ctd','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'time_ctd', 'long_name', 'science time');
    ncwriteatt(ncfname, 'time_ctd', 'units', 'seconds since 1970-01-01 00:00:00');

    nccreate(ncfname,'lat','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'lat', 'standard_name', 'latitude');
    ncwriteatt(ncfname, 'lat', 'long_name', 'latitude');
    ncwriteatt(ncfname, 'lat', 'units', 'degrees north');

    nccreate(ncfname,'lon','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'lon', 'standard_name', 'longitude');
    ncwriteatt(ncfname, 'lon', 'long_name', 'longitude');
    ncwriteatt(ncfname, 'lon', 'units', 'degrees east');
    
    nccreate(ncfname,'wpt_lat','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'wpt_lat', 'standard_name', 'wpt latitude');
    ncwriteatt(ncfname, 'wpt_lat', 'long_name', 'waypoint latitude');
    ncwriteatt(ncfname, 'wpt_lat', 'units', 'degrees north');

    nccreate(ncfname,'wpt_lon','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'wpt_lon', 'standard_name', 'wpt longitude');
    ncwriteatt(ncfname, 'wpt_lon', 'long_name', 'waypoint longitude');
    ncwriteatt(ncfname, 'wpt_lon', 'units', 'degrees east');

    nccreate(ncfname,'distance_over_ground','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'distance_over_ground', 'standard_name', 'distance_over_ground');
    ncwriteatt(ncfname, 'distance_over_ground', 'long_name', 'cummulative distance over ground since deployment start');
    ncwriteatt(ncfname, 'distance_over_ground', 'units', 'km');

    nccreate(ncfname,'pitch','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'pitch', 'standard_name', 'pitch');
    ncwriteatt(ncfname, 'pitch', 'long_name', 'glider pitch angle');
    ncwriteatt(ncfname, 'pitch', 'units', 'degrees');

    nccreate(ncfname,'roll','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'roll', 'standard_name', 'roll');
    ncwriteatt(ncfname, 'roll', 'long_name', 'glider roll angle');
    ncwriteatt(ncfname, 'roll', 'units', 'degrees');

    nccreate(ncfname,'heading','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'heading', 'standard_name', 'heading');
    ncwriteatt(ncfname, 'heading', 'long_name', 'glider heading angle');
    ncwriteatt(ncfname, 'heading', 'units', 'degrees');

    nccreate(ncfname,'water_u','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'water_u', 'standard_name', 'water_east_velocity');
    ncwriteatt(ncfname, 'water_u', 'long_name', 'mean eastward water velocity in segment');
    ncwriteatt(ncfname, 'water_u', 'units', 'm s-1');

    nccreate(ncfname,'water_v','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'water_v', 'standard_name', 'water_north_velocity');
    ncwriteatt(ncfname, 'water_v', 'long_name', 'mean northward water velocity in segment');
    ncwriteatt(ncfname, 'water_v', 'units', 'm s-1');

    nccreate(ncfname,'profile_index','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'profile_index', 'long_name', 'number of profiles');
    ncwriteatt(ncfname, 'profile_index', 'units', 'dimensionless');

    nccreate(ncfname,'profile_direction','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'profile_direction', 'long_name', '-down/+up  direction of profiles');
    ncwriteatt(ncfname, 'profile_direction', 'units', 'dimensionless');


    nccreate(ncfname,'depth','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'depth', 'standard_name', 'glider_depth');
    ncwriteatt(ncfname, 'depth', 'long_name', 'glider depth');
    ncwriteatt(ncfname, 'depth', 'units', 'm');
    ncwriteatt(ncfname, 'depth', 'derived_from', 'seawater library v3.3, seabird pressure filter');

    ncwrite(ncfname,'lat',dat.lat);
    ncwrite(ncfname,'lon',dat.lon);
    ncwrite(ncfname,'wpt_lat',dat.wpt_lat);
    ncwrite(ncfname,'wpt_lon',dat.wpt_lon);
    
    ncwrite(ncfname,'time',dat.time);
    ncwrite(ncfname,'time_unix',dat.time_unix);
    ncwrite(ncfname,'time_ctd',dat.time_ctd);

    ncwrite(ncfname,'pitch',dat.pitch);
    ncwrite(ncfname,'roll',dat.roll);
    ncwrite(ncfname,'heading',dat.heading);
    ncwrite(ncfname,'distance_over_ground',dat.distx);

    ncwrite(ncfname,'water_u',dat.glider_u);
    ncwrite(ncfname,'water_v',dat.glider_v);

    ncwrite(ncfname,'profile_index',dat.prof_idx);
    ncwrite(ncfname,'profile_direction',dat.profile_dir);
    ncwrite(ncfname,'depth',dat.depth);

    %% SCIENCE
    nccreate(ncfname,'temperature','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'temperature', 'standard_name', 'water_temperature');
    ncwriteatt(ncfname, 'temperature', 'long_name', 'ctd_cell_water_temperature');
    ncwriteatt(ncfname, 'temperature', 'units', 'ITS90 deg C');
    ncwriteatt(ncfname, 'temperature', 'missing_value', 'NaN');

    nccreate(ncfname,'pressure','Dimensions',{'time', x_dim });
    ncwriteatt(ncfname, 'pressure', 'standard_name', 'water_pressure');
    ncwriteatt(ncfname, 'pressure', 'long_name', 'gpctd_cell_water_pressure');
    ncwriteatt(ncfname, 'pressure', 'units', 'dbar');
    ncwriteatt(ncfname, 'pressure', 'derived_from', 'seabird pressure signal filter');
    ncwriteatt(ncfname, 'pressure', 'missing_value', 'NaN');

    nccreate(ncfname,'conductivity','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'conductivity', 'standard_name', 'water_conductivity');
    ncwriteatt(ncfname, 'conductivity', 'long_name', 'ctd_cell_water_conductivity');
    ncwriteatt(ncfname, 'conductivity', 'units', 'S m-1');
    ncwriteatt(ncfname, 'conductivity', 'missing_value', 'NaN');

    nccreate(ncfname,'salinity','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'salinity', 'standard_name', 'water_salinity');
    ncwriteatt(ncfname, 'salinity', 'long_name', 'practical_salinity');
    ncwriteatt(ncfname, 'salinity', 'units', 'PSS-78 PSU');
    ncwriteatt(ncfname, 'salinity', 'missing_value', 'NaN');
    ncwriteatt(ncfname, 'salinity', 'derived_from', 'seawater library v3.3');

    nccreate(ncfname,'abs_salinity','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname, 'abs_salinity', 'standard_name', 'water_salinity');
    ncwriteatt(ncfname, 'abs_salinity', 'long_name', 'absolute_salinity');
    ncwriteatt(ncfname, 'abs_salinity', 'units', 'g kg-1');
    ncwriteatt(ncfname, 'abs_salinity', 'missing_value', 'NaN');
    ncwriteatt(ncfname, 'abs_salinity', 'derived_from', 'GSW Teos toolbox');

    nccreate(ncfname,'density','Dimensions',{'time' x_dim});
    ncwriteatt(ncfname,'density', 'standard_name', 'density');
    ncwriteatt(ncfname, 'density', 'long_name', 'in situ density');
    ncwriteatt(ncfname, 'density', 'units', 'kg m-3');
    ncwriteatt(ncfname, 'density' , 'missing_value', 'NaN');
    ncwriteatt(ncfname, 'density', 'derived_from', 'Seawater library v3.3');

    ncwrite(ncfname,'pressure',dat.pressure);
    ncwrite(ncfname,'temperature',dat.temp_ctd);
    ncwrite(ncfname,'conductivity',dat.cond_ctd);
    ncwrite(ncfname,'salinity',dat.salt_ctd);
    ncwrite(ncfname,'abs_salinity',dat.salinity_abs);
    ncwrite(ncfname,'density',dat.dens_ctd);

    if strcmp(options.thermal_lag,'yes')
        nccreate(ncfname,'temperature_lag_correct','Dimensions',{'time' x_dim});
        ncwriteatt(ncfname,'temperature_lag_correct', 'standard_name', 'cond_cell_temperature');
        ncwriteatt(ncfname,'temperature_lag_correct', 'long_name','cond_cell_temperature');
        ncwriteatt(ncfname,'temperature_lag_correct', 'units', 'deg C');
        ncwriteatt(ncfname,'temperature_lag_correct', 'missing_value', 'NaN');
        ncwriteatt(ncfname,'temperature_lag_correct', 'thermal_lag_algorithm','Garau_2011_SOCIB_toolbox');

        nccreate(ncfname,'salinity_lag_correct','Dimensions',{'time' x_dim});
        ncwriteatt(ncfname, 'salinity_lag_correct', 'standard_name', 'water_salinity');
        ncwriteatt(ncfname, 'salinity_lag_correct', 'long_name', 'corrected_practical_salinity');
        ncwriteatt(ncfname, 'salinity_lag_correct', 'units', 'PSS-78 PSU');
        ncwriteatt(ncfname, 'salinity_lag_correct', 'missing_value', 'NaN');
        ncwriteatt(ncfname, 'salinity_lag_correct', 'thermal_lag_algorithm', 'Garau_2011_SOCIB_toolbox');

        nccreate(ncfname,'conductivity_lag_correct','Dimensions',{'time' x_dim});
        ncwriteatt(ncfname, 'conductivity_lag_correct', 'standard_name', 'water_conductivity');
        ncwriteatt(ncfname, 'conductivity_lag_correct', 'long_name', 'corrected_conductivity');
        ncwriteatt(ncfname, 'conductivity_lag_correct', 'units', 'S/m');
        ncwriteatt(ncfname, 'conductivity_lag_correct', 'missing_value', 'NaN');
        ncwriteatt(ncfname, 'conductivity_lag_correct', 'thermal_lag_algorithm', 'Garau_2011_SOCIB_toolbox');

        nccreate(ncfname,'abs_salinity_lag_correct','Dimensions',{'time' x_dim});
        ncwriteatt(ncfname, 'abs_salinity_lag_correct', 'standard_name', 'abs_water_salinity');
        ncwriteatt(ncfname, 'abs_salinity_lag_correct', 'long_name', 'absolute_corrected_practical_salinity');
        ncwriteatt(ncfname, 'abs_salinity_lag_correct', 'units', 'g/kg');
        ncwriteatt(ncfname, 'abs_salinity_lag_correct', 'missing_value', 'NaN');
        ncwriteatt(ncfname, 'abs_salinity_lag_correct', 'derived_from','GSW Teos toolbox');   

        nccreate(ncfname,'density_lag_correct','Dimensions',{'time' x_dim});
        ncwriteatt(ncfname,'density_lag_correct', 'standard_name', 'density');
        ncwriteatt(ncfname,'density_lag_correct', 'long_name', 'in situ density from lag corrected salinity');
        ncwriteatt(ncfname, 'density_lag_correct', 'units', 'kg m-3');
        ncwriteatt(ncfname, 'density_lag_correct' , 'missing_value', 'NaN');
        ncwriteatt(ncfname, 'density_lag_correct', 'derived_from', 'Seawater library v3.3');

        ncwrite(ncfname,'temperature_lag_correct',dat.temp_ctd_thermal_corrected);
        ncwrite(ncfname,'conductivity_lag_correct',dat.cond_ctd_thermal_corrected);
        ncwrite(ncfname,'salinity_lag_correct',dat.salt_ctd_thermal_corrected);
        ncwrite(ncfname,'abs_salinity_lag_correct',dat.salinity_abs_thermal_corrected);
        ncwrite(ncfname,'density_lag_correct',dat.dens_ctd_thermal_corrected);


    end

    if strcmp(options.oxy4,'yes')
        nccreate(ncfname,'oxygen_saturation','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'oxygen_saturation', 'standard_name', 'oxygen_saturation');
        ncwriteatt(ncfname, 'oxygen_saturation', 'long_name', 'oxygen_saturation_wrt_0dbar');
        ncwriteatt(ncfname, 'oxygen_saturation', 'units','%');
        ncwriteatt(ncfname, 'oxygen_saturation', 'missing_value','NaN');
        ncwriteatt(ncfname, 'oxygen_saturation', 'derived_from', 'TEOS10 implementation of Garcia and Gordon, 1993 and optode oxygen, CTD density');

        nccreate(ncfname,'oxygen_concentration','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'oxygen_concentration', 'standard_name', 'oxygen_concentration');
        ncwriteatt(ncfname, 'oxygen_concentration', 'long_name', 'in_situ_oxygen_concentration_optode_4831');
        ncwriteatt(ncfname, 'oxygen_concentration', 'units', 'umol L-1');
        ncwriteatt(ncfname, 'oxygen_concentration', 'missing_value', 'NaN');
        ncwriteatt(ncfname, 'oxygen_concentration', 'derived_from', 'Aanderaa Optode Manual, Uchida 2008, Code by Nicolai Bronikowski 2018, and Henry Bittig 2013');
        ncwriteatt(ncfname, 'oxygen_concentration', 'phase_mode', '7 point coefficient');

        nccreate(ncfname,'oxygen_calphase','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'oxygen_calphase', 'standard_name', 'oxy4_calphase');
        ncwriteatt(ncfname, 'oxygen_calphase', 'long_name', 'oxy4_calphase');
        ncwriteatt(ncfname, 'oxygen_calphase', 'units', 'deg');
        ncwriteatt(ncfname, 'oxygen_calphase', 'missing_value', 'NaN');


        nccreate(ncfname,'oxygen_SVU_coefficients','Dimensions',{'SVU Dimension',svu_dim});
        ncwriteatt(ncfname,'oxygen_SVU_coefficients', 'standard_name', 'foil_coefficients');


        ncwrite(ncfname,'oxygen_saturation',dat.oxy_sat);
        ncwrite(ncfname,'oxygen_concentration',dat.oxy_conc);
        ncwrite(ncfname,'oxygen_calphase',dat.oxy_calphase);
        ncwrite(ncfname,'oxygen_SVU_coefficients',dat.oxy_SVU_foil_coef);

    end

    if strcmp(options.oxy4_correction,'yes')
        nccreate(ncfname,'oxygen_saturation_corrected','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'oxygen_saturation_corrected', 'standard_name', 'oxygen_saturation_corrected');
        ncwriteatt(ncfname, 'oxygen_saturation_corrected', 'long_name', 'oxygen_saturation_wrt_0dbar_corrected_for_oxygen_sensor_response_time_lag_bittig_2018');
        ncwriteatt(ncfname, 'oxygen_saturation_corrected', 'units','%');
        ncwriteatt(ncfname, 'oxygen_saturation_corrected', 'missing_value','NaN');
        ncwriteatt(ncfname, 'oxygen_saturation_corrected', 'derived_from', 'TEOS10 implementation of Garcia and Gordon, 1993 and optode oxygen, CTD density, Using Corrected Oxygen Concentration');

        nccreate(ncfname,'oxygen_concentration_corrected','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'oxygen_concentration_corrected', 'standard_name', 'oxygen_concentration_corrected');
        ncwriteatt(ncfname, 'oxygen_concentration_corrected', 'long_name', 'in_situ_oxygen_concentration_optode_4831_corrected_for_response_time_lag_bittig_2018');
        ncwriteatt(ncfname, 'oxygen_concentration_corrected', 'units', 'umol L-1');
        ncwriteatt(ncfname, 'oxygen_concentration_corrected', 'missing_value', 'NaN');
        ncwriteatt(ncfname, 'oxygen_concentration_corrected', 'derived_from', 'Aanderaa Optode Manual, Uchida 2008, Code by Nicolai Bronikowski 2018, and Henry Bittig 2013,Correction Bittig 2018');
        ncwriteatt(ncfname, 'oxygen_concentration_corrected', 'phase_mode', '7 point coefficient');

        ncwrite(ncfname,'oxygen_saturation_corrected',dat.oxy_sat_corrected);
        ncwrite(ncfname,'oxygen_concentration_corrected',dat.oxy_conc_corrected);

    end

    if strcmp(options.oxy3835,'yes')
        nccreate(ncfname,'oxygen_saturation','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'oxygen_saturation', 'standard_name', 'oxygen_saturation');
        ncwriteatt(ncfname, 'oxygen_saturation', 'long_name', 'oxygen_saturation_wrt_0dbar');
        ncwriteatt(ncfname, 'oxygen_saturation', 'units','%');
        ncwriteatt(ncfname, 'oxygen_saturation', 'missing_value','NaN');
        ncwriteatt(ncfname, 'oxygen_saturation', 'derived_from', 'TEOS10 implementation of Garcia and Gordon, 1993 and optode oxygen, CTD density');

        nccreate(ncfname,'oxygen_concentration','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'oxygen_concentration', 'standard_name', 'oxygen_concentration');
        ncwriteatt(ncfname, 'oxygen_concentration', 'long_name', 'in_situ_oxygen_concentration_optode_3835');
        ncwriteatt(ncfname, 'oxygen_concentration', 'units', 'umol L-1');
        ncwriteatt(ncfname, 'oxygen_concentration', 'missing_value', 'NaN');
        ncwriteatt(ncfname, 'oxygen_concentration', 'derived_from', 'optode_internal')
        ncwriteatt(ncfname, 'oxygen_concentration', 'comment', 'not_corrected')

        ncwrite(ncfname,'oxygen_saturation',dat.oxy_sat);
        ncwrite(ncfname,'oxygen_concentration',dat.oxy_conc);
    end


    if strcmp(options.co2,'yes')
        nccreate(ncfname,'pCO2','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'pCO2', 'standard_name', 'pco2');
        ncwriteatt(ncfname, 'pCO2', 'long_name', 'partial_pressure_of_CO2');
        ncwriteatt(ncfname, 'pCO2', 'units','micro-atmospheres');
        ncwriteatt(ncfname, 'pCO2', 'missing_value','NaN');
        ncwriteatt(ncfname, 'pCO2', 'derived_from', 'Atamanchuk et al., 2014');

        nccreate(ncfname,'CO2_calphase','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'CO2_calphase', 'standard_name', 'pco2_calphase');
        ncwriteatt(ncfname, 'CO2_calphase', 'long_name', 'CO2_optode_sensor_calphase');
        ncwriteatt(ncfname, 'CO2_calphase', 'units','deg');
        ncwriteatt(ncfname, 'CO2_calphase', 'missing_value','NaN');
        ncwriteatt(ncfname, 'CO2_calphase', 'derived_from', 'temperature');
        
        nccreate(ncfname,'CO2_dphase','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'CO2_dphase', 'standard_name', 'pco2_dphase');
        ncwriteatt(ncfname, 'CO2_dphase', 'long_name', 'CO2_optode_sensor_dphase');
        ncwriteatt(ncfname, 'CO2_dphase', 'units','deg');
        ncwriteatt(ncfname, 'CO2_dphase', 'missing_value','NaN');
        ncwriteatt(ncfname, 'CO2_dphase', 'derived_from', 'sensor');

        ncwrite(ncfname,'pCO2',dat.pco2);
        ncwrite(ncfname,'CO2_calphase',dat.co2_calphase);
        ncwrite(ncfname,'CO2_dphase',dat.co2_dphase);

    end

    if strcmp(options.flbbcd,'yes')
        nccreate(ncfname,'cdom_units','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'cdom_units', 'standard_name', 'cdom');
        ncwriteatt(ncfname, 'cdom_units', 'long_name', 'coloured_dissolved_organic_matter');
        ncwriteatt(ncfname, 'cdom_units', 'units','ppm');
        ncwriteatt(ncfname, 'cdom_units', 'missing_value','NaN');

        nccreate(ncfname,'chlor_units','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname,'chlor_units', 'standard_name', 'chl-a');
        ncwriteatt(ncfname,'chlor_units', 'long_name', 'chlorophyll-a');
        ncwriteatt(ncfname,'chlor_units', 'units','micro g L-1');
        ncwriteatt(ncfname,'chlor_units', 'missing_value','NaN');
        
        nccreate(ncfname,'bb700_units','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname,'bb700_units', 'standard_name', 'backscatter');
        ncwriteatt(ncfname,'bb700_units', 'long_name', 'backscatter_700nm');
        ncwriteatt(ncfname,'bb700_units', 'units','m-1 sr-1');
        ncwriteatt(ncfname,'bb700_units', 'missing_value','NaN');

        nccreate(ncfname,'cdom_ref','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname,'cdom_ref', 'standard_name', 'ref_cdom');
        ncwriteatt(ncfname,'cdom_ref', 'long_name', 'ref_coloured_dissolved_organic_matter');
        ncwriteatt(ncfname,'cdom_ref', 'units','counts');
        ncwriteatt(ncfname, 'cdom_ref', 'missing_value','NaN');

        nccreate(ncfname,'chlor_ref','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname,'chlor_ref', 'standard_name', 'ref_chl-a');
        ncwriteatt(ncfname, 'chlor_ref', 'long_name', 'ref_chlorophyll-a');
        ncwriteatt(ncfname, 'chlor_ref', 'units','counts');
        ncwriteatt(ncfname, 'chlor_ref', 'missing_value','NaN');
        
        nccreate(ncfname,'bb700_ref','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'bb700_ref', 'standard_name', 'ref_backscatter');
        ncwriteatt(ncfname, 'bb700_ref', 'long_name', 'ref_backscatter_700nm');
        ncwriteatt(ncfname,'bb700_ref', 'units','counts');
        ncwriteatt(ncfname,'bb700_ref', 'missing_value','NaN');

        nccreate(ncfname,'cdom_sig','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'cdom_sig', 'standard_name', 'sig_cdom');
        ncwriteatt(ncfname, 'cdom_sig', 'long_name', 'ref_coloured_dissolved_organic_matter');
        ncwriteatt(ncfname, 'cdom_sig', 'units','counts');
        ncwriteatt(ncfname,'cdom_sig', 'missing_value','NaN');

        nccreate(ncfname,'chlor_sig','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'chlor_sig', 'standard_name', 'sig_chl-a');
        ncwriteatt(ncfname, 'chlor_sig', 'long_name', 'sig_chlorophyll-a');
        ncwriteatt(ncfname, 'chlor_sig', 'units','counts');
        ncwriteatt(ncfname, 'chlor_sig', 'missing_value','NaN');
        
        nccreate(ncfname,'bb700_sig','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'bb700_sig', 'standard_name', 'sig_backscatter');
        ncwriteatt(ncfname, 'bb700_sig', 'long_name', 'sig_backscatter_700nm');
        ncwriteatt(ncfname, 'bb700_sig', 'units','counts');
        ncwriteatt(ncfname, 'bb700_sig', 'missing_value','NaN');


        nccreate(ncfname,'flbbcd_thermal','Dimensions',{'time', x_dim });
        ncwriteatt(ncfname, 'flbbcd_thermal', 'standard_name', 'instrument_thermal');
        ncwriteatt(ncfname, 'flbbcd_thermal', 'long_name', 'flbbcd_thermal');
        ncwriteatt(ncfname, 'flbbcd_thermal', 'units','counts');
        ncwriteatt(ncfname, 'flbbcd_thermal', 'missing_value','NaN');


        nccreate(ncfname,'bb700_cwo');
        ncwriteatt(ncfname, 'bb700_cwo', 'long_name', 'backscatter_700nm_clear_water_offset');
        ncwriteatt(ncfname, 'bb700_cwo', 'units','counts');

        nccreate(ncfname,'cdom_cwo');
        ncwriteatt(ncfname, 'cdom_cwo', 'long_name', 'cdom_clear_water_offset');
        ncwriteatt(ncfname, 'cdom_cwo', 'units','counts');

        nccreate(ncfname,'chlor_cwo');
        ncwriteatt(ncfname, 'chlor_cwo', 'long_name', 'cdom_clear_water_offset');
        ncwriteatt(ncfname, 'chlor_cwo', 'units','counts');

        nccreate(ncfname,'bb700_sf');
        ncwriteatt(ncfname, 'bb700_sf', 'long_name', 'backscatter_700nm_scale_factor');
        ncwriteatt(ncfname, 'bb700_sf', 'units','m-1 sr-1 counts-1');

        nccreate(ncfname,'cdom_sf');
        ncwriteatt(ncfname,'cdom_sf', 'long_name', 'cdom_scale_factor');
        ncwriteatt(ncfname,'cdom_sf','units','ppb count-1');

        nccreate(ncfname,'chlor_sf');
        ncwriteatt(ncfname,'chlor_sf', 'long_name', 'chlor_scale_factor');
        ncwriteatt(ncfname,'chlor_sf', 'units','micro-grams L-1 counts-1');




        ncwrite(ncfname,'cdom_units',dat.cdom_units);
        ncwrite(ncfname,'chlor_units',dat.chlorophyll_units);
        ncwrite(ncfname,'bb700_units',dat.backscatter_units);
        ncwrite(ncfname,'cdom_ref',dat.cdom_ref);
        ncwrite(ncfname,'chlor_ref',dat.chlorophyll_ref);
        ncwrite(ncfname,'bb700_ref',dat.backscatter_ref);
        ncwrite(ncfname,'cdom_sig',dat.cdom_sig);
        ncwrite(ncfname,'chlor_sig',dat.chlorophyll_sig);
        ncwrite(ncfname,'bb700_sig',dat.backscatter_sig);
        ncwrite(ncfname,'flbbcd_thermal',dat.optics_therm);

        
        ncwrite(ncfname,'chlor_cwo',dat.chlor_cwo);
        ncwrite(ncfname,'bb700_cwo',dat.bb_cwo);
        ncwrite(ncfname,'cdom_cwo',dat.cdom_cwo);

        ncwrite(ncfname,'chlor_sf',dat.chlor_sf);
        ncwrite(ncfname,'bb700_sf',dat.bb_sf);
        ncwrite(ncfname,'cdom_sf',dat.cdom_sf);

    end

    % Header Info
    ncwriteatt(ncfname,'/','file_creation_date',datestr(now));
    ncwriteatt(ncfname,'/','file_author',dat.author);
    ncwriteatt(ncfname,'/','contact_email',dat.author_email);
    ncwriteatt(ncfname,'/','project_name',dat.project_title);
    ncwriteatt(ncfname,'/','glider_name',dat.glider_name);
    ncwriteatt(ncfname,'/','glider_serial',dat.glider_serial);
    ncwriteatt(ncfname,'/','glider_type',dat.glider_type);
    ncwriteatt(ncfname,'/','glider_configuration',dat.glider_configuration);
    ncwriteatt(ncfname,'/','glider_sensors',dat.glider_sensors);
    ncwriteatt(ncfname,'/','glider_comments',dat.comments);
    ncwriteatt(ncfname,'/','institution_name',dat.institution);
    ncwriteatt(ncfname,'/','deployment_region',dat.deployment_region);
    ncwriteatt(ncfname,'/','deployment_start_date',dat.deployment_start);
    ncwriteatt(ncfname,'/','deployment_end_date',dat.deployment_end);
    ncwriteatt(ncfname,'/','funding_source',dat.funding);
    ncwriteatt(ncfname,'/','researcher_names',dat.deploymentPIs);
    ncwriteatt(ncfname,'/','longitude_extent(min,max)',[num2str(nanmin(dat.lon)),' ,', num2str(nanmax(dat.lon))]);
    ncwriteatt(ncfname,'/','latitude_extent(min,max)',[num2str(nanmin(dat.lat)),' ,', num2str(nanmax(dat.lat))]);

    ncdisp(ncfname)

    system(['mv ',ncfname,' ',options.path])
end
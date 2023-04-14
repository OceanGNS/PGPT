def XXXXsave_netcdf(data, raw_data, source_info):
	"""
	Save processed and raw glider data to a NetCDF file.
	
	Args:
	data (pd.DataFrame): Processed glider data.
	raw_data (pd.DataFrame): Raw glider data.
	source_info (pd.DataFrame): Information about the data and data tags
	"""
	print("Current file path:", os.path.realpath(__file__))
	output_fn = source_info['filepath'] + source_info['filename']
	
	if not data.empty:
		data = data.set_index('time').to_xarray()
		data_attributes(data, source_info)
	
		with nc4.Dataset(output_fn, 'w', format='NETCDF4') as nc_data:
			# Transfer dimensions, variables, and attributes from the xarray Dataset to the NetCDF file
			for name, dim in data.dims.items():
				nc_data.createDimension(name, dim)
				
			for name, var in data.variables.items():
				nc_var = nc_data.createVariable(name, var.dtype, var.dims)
				nc_var.setncatts(var.attrs)
				nc_var[:] = var.values
				
			for name, attr in data.attrs.items():
				nc_data.setncattr(name, attr)

			# Set the source attribute directly using netCDF4
			nc_data.source = source_info['data_source']

	if not raw_data.empty:
		raw_data = raw_data.set_index('time').to_xarray()
		
		with nc4.Dataset(output_fn, 'a') as nc_data:
			glider_record_group = nc_data.createGroup('glider_record')
			
			for name, dim in raw_data.dims.items():
				glider_record_group.createDimension(name, dim)
				
			for name, var in raw_data.variables.items():
				nc_var = glider_record_group.createVariable(name, var.dtype, var.dims)
				nc_var.setncatts(var.attrs)
				nc_var[:] = var.values
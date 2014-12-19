class SetBoilerCapacity < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "SetBoilerCapacity"
  end

  # human readable description
  def description
    return "This measure reads the boiler capacity from an EnergyPlus output file, and sets the boiler capacity in the model to that value.  This prevents the autosizing of the boiler, so the simulation will capture the proper part-load efficiency if other energy efficiency measures are implemented."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Reads the Boiler Nominal Capacity from an EnergyPlus .eio file and hardsizes the Nominal Capacity of the Boiler to this value."
  end

  # define the arguments that the user will input
  def arguments(model)
	args = OpenStudio::Ruleset::OSArgumentVector.new
	
	# Determine how many boilers in model
    boiler_handles = OpenStudio::StringVector.new
    boiler_display_names = OpenStudio::StringVector.new

    # Get/show all boiler units from current loaded model.
    boiler_handles << '0'
    boiler_display_names << '*All boilers*'

    i_boiler = 0
    model.getBoilerHotWaters.each do |boiler_water|
      #if not boiler_water.to_BoilerHotWater.empty?
        water_unit = boiler_water.to_BoilerHotWater.get
        boiler_handles << i_boiler.to_s
        boiler_display_names << water_unit.name.to_s
        i_boiler += i_boiler
	  #end
    end

    model.getBoilerSteams.each do |boiler_steam|
      #if not boiler_steam.to_BoilerSteam.empty?
        steam_unit = boiler_water.to_BoilerSteam.get
        boiler_handles << i_boiler.to_s
        boiler_display_names << steam_unit.name.to_s
        i_boiler += i_boiler
	  #end
    end

	boiler_bool = OpenStudio::Ruleset::OSArgument::makeBoolArgument("boiler_bool")
	
    if i_boiler == 0
      boiler_bool.setDisplayName("!!!!*** This Measure is not Applicable to loaded Model. Read the description and choose an appropriate baseline model. ***!!!!")
      boiler_bool.setDefaultValue(true)
      args << boiler_bool
	else 
	  boiler_bool = OpenStudio::Ruleset::OSArgument::makeBoolArgument("boiler_bool")
      boiler_bool.setDisplayName("Measure NOT applicable:")
      boiler_bool.setDefaultValue(false)
      args << boiler_bool
    end

    boiler_name = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("boiler_name", boiler_handles, boiler_display_names,true)
    boiler_name.setDisplayName("Apply the measure to:")
    boiler_name.setDefaultValue(boiler_display_names[0])
    args << boiler_name
	
    # the sql filename and location to be used
    sql_fname = OpenStudio::Ruleset::OSArgument.makeStringArgument("sql_fname", true)
	sql_fname.setDescription("Please select the SQL file to use for hard-sizing.")
    sql_fname.setDisplayName("sql_fname")
	sql_fname.setDefaultValue("sql_fname")    
    args << sql_fname

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
	# Determine if the measure is applicable to the model, if not just return and no changes are made.
	# boiler_bool is false if the measure is applicable, and true if it is not
	boiler_bool = runner.getBoolArgumentValue("boiler_bool", user_arguments)
	if boiler_bool
	  runner.registerInfo("This measure is not applicable.")
	  return true
	end

    # assign the user inputs to variables
	boiler_name = runner.getOptionalWorkspaceObjectChoiceValue("boiler_name", user_arguments, model)
	handle = runner.getStringArgumentValue("boiler_name", user_arguments)
	boiler_index = handle.to_i
    sql_fname = runner.getStringArgumentValue("sql_fname", user_arguments)

	# Open the sql file
	sql_path = OpenStudio::Path.new(sql_fname)
	# if the sql file exists, load it into the variable sql
	if OpenStudio::exists(sql_path)
	  sql = OpenStudio::SqlFile.new(sql_path)
	else 
	  runner.registerError("#{sql_fname} was not found. Make sure the sql file location is valid.")
	  return false
	end
	
	capacities_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName = 'EquipmentSummary' AND ReportForString='Entire Facility' AND TableName = 'Central Plant' AND ColumnName = 'Nominal Capacity'"	
	boiler_names_query = "SELECT RowName FROM TabularDataWithStrings WHERE ReportName = 'EquipmentSummary' AND ReportForString='Entire Facility' AND TableName = 'Central Plant' AND ColumnName = 'Nominal Capacity'"
	boiler_names_sql = sql.execAndReturnVectorOfString(boiler_names_query).get
	boiler_capacities_sql = sql.execAndReturnVectorOfDouble(capacities_query).get
	sql.close
	
	#loop through to find water boiler
	i_boiler = 0
	model.getBoilerHotWaters.each do |boiler_water|
	  if not boiler_water.to_BoilerHotWater.empty?
		i_boiler = i_boiler + 1
		if boiler_index != 0 and (boiler_index != i_boiler)
			next
		end
		water_unit = boiler_water.to_BoilerHotWater.get
		unit_name = water_unit.name.to_s

		# report initial nominal capacity field of the target boiler
		nominal_capacity = water_unit.nominalCapacity()
		runner.registerInitialCondition("#{unit_name} started with a nominal capacity of #{nominal_capacity}.")
		
		boiler_in_sql = 0
		boiler_sql_index = 0
		boiler_names_sql.each do |boiler_name_sql|
		  boiler_match = (boiler_name_sql.casecmp unit_name)
		  if boiler_match == 0
		    boiler_in_sql = 1
			nominal_capacity = boiler_capacities_sql[boiler_sql_index]
			runner.registerFinalCondition("The boiler '#{unit_name}' found in SQL file with nominal capacity of #{nominal_capacity}")
		    break
		  end
		  boiler_sql_index = boiler_sql_index + 1		
		end		
		
		# set the nominal capacity based on the SQL file if the boiler was found in the SQL file
		if boiler_in_sql == 1
		  water_unit.setNominalCapacity(nominal_capacity)
		  runner.registerFinalCondition("The nominal capacity for '#{unit_name}' was set to #{nominal_capacity}")
		else 
		  water_unit.autosizeNominalCapacity()
		  runner.registerFinalCondition("The nominal capacity for '#{unit_name}' was set to Autosize")
		end 		
		
		end
	end
	
	#loop through to find steam boiler
	model.getBoilerSteams.each do |boiler_steam|
	  if not boiler_steam.to_BoilerSteam.empty?
		i_boiler = i_boiler + 1
		if boiler_index != 0 and (boiler_index != i_boiler)
			next
		end
		steam_unit = boiler.to_BoilerSteam.get
		steam_unit_fueltype = steam_unit.fuelType
		unit_name = steam_unit.name.to_s

		# report initial nominal capacity field of the target boiler
		nominal_capacity = steam_unit.nominalCapacity()
		runner.registerInitialCondition("#{unit_name} started with a nominal capacity of #{nominal_capacity}.")
		
		boiler_in_sql = 0
		boiler_sql_index = 0
		boiler_names_sql.each do |boiler_name_sql|
		  boiler_match = (boiler_name_sql.casecmp unit_name)
		  if boiler_match == 0
		    boiler_in_sql = 1
			nominal_capacity = boiler_capacities_sql[boiler_sql_index]
			runner.registerFinalCondition("The boiler '#{unit_name}' found in SQL file with nominal capacity of #{nominal_capacity}")
		    break
		  end
		  boiler_sql_index = boiler_sql_index + 1		
		end		
		
		# set the nominal capacity based on the SQL file if the boiler was found in the SQL file
		if boiler_in_sql == 1
		  steam_unit.setNominalCapacity(nominal_capacity)
		  runner.registerFinalCondition("The nominal capacity for '#{unit_name}' was set to #{nominal_capacity}")
		else 
		  steam_unit.autosizeNominalCapacity()
		  runner.registerFinalCondition("The nominal capacity for '#{unit_name}' was set to Autosize")
		end 		
		
		end
	end
	
    return true
  end
  
end

# register the measure to be used by the application
SetBoilerCapacity.new.registerWithApplication

class SetBoilerThermalEfficiencyAndAutosize < OpenStudio::Ruleset::ModelUserScript
  def name
    'SetBoilerThermalEfficiencyAndAutosize'
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
      boiler_bool.setDisplayName("Measure applicable:")
      boiler_bool.setDefaultValue(false)
      args << boiler_bool
    end

    boiler_name = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("boiler_name", boiler_handles, boiler_display_names,true)
    boiler_name.setDisplayName("Apply the measure to:")
    boiler_name.setDefaultValue(boiler_display_names[0])
    args << boiler_name

    # Boiler Thermal Efficiency (default of 0.8)
    boiler_thermal_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boiler_thermal_efficiency")
    boiler_thermal_efficiency.setDisplayName("Boiler nominal thermal efficiency (between 0 and 1)")
    boiler_thermal_efficiency.setDefaultValue(0.8)
    args << boiler_thermal_efficiency

    # Boiler Design Outlet Temperature (default of 140)
    boiler_outlet_temperature_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boiler_outlet_temperature_ip")
    boiler_outlet_temperature_ip.setDisplayName("Boiler outlet temperature")
    boiler_outlet_temperature_ip.setDefaultValue(140)
    args << boiler_outlet_temperature_ip

	# Add a check box for specify thermal efficiency manually
	is_capacity_manual = OpenStudio::Ruleset::OSArgument::makeBoolArgument("is_capacity_manual", false)
	is_capacity_manual.setDisplayName("Option: manual boiler nominal capacity")
	is_capacity_manual.setDefaultValue(false)
	args << is_capacity_manual
	
    # Nominal Capacity [W] (default of blank)
    nominal_capacity_si = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nominal_capacity_si", false)
    nominal_capacity_si.setDisplayName("Boiler nominal capacity [W] ")
    args << nominal_capacity_si

    return args
  end #end the arguments method

  def changeThermalEfficiency(model, boiler_index, boiler_thermal_efficiency, boiler_outlet_temperature_si, is_capacity_manual, nominal_capacity_si, runner)
    i_boiler = 0
	
	#loop through to find water boiler
	model.getBoilerHotWaters.each do |boiler_water|
	  if not boiler_water.to_BoilerHotWater.empty?
		i_boiler = i_boiler + 1
		if boiler_index != 0 and (boiler_index != i_boiler)
			next
		end
		water_unit = boiler_water.to_BoilerHotWater.get
		unit_name = water_unit.name
		# check capacity, fuel type, and thermal efficiency
		thermal_efficiency_old = water_unit.nominalThermalEfficiency()
		outlet_temperature_old = water_unit.designWaterOutletTemperature()
		#if thermal_efficiency_old.nil?
		if not thermal_efficiency_old.is_a? Numeric
		  runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was not set.")
		else
		  runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was not set.")
		end
		#if outlet_temperature_old.nil?
		if not outlet_temperature_old.is_a? Numeric
		  runner.registerInfo("Initial: The Design Outlet Temperature for '#{unit_name}' was not set.")
		else
		  runner.registerInfo("Initial: The Design Outlet Temperature for '#{unit_name}' was not set.")
		end

		water_unit.setNominalThermalEfficiency(boiler_thermal_efficiency)
		water_unit.setDesignWaterOutletTemperature(boiler_outlet_temperature_si)
		
		if is_capacity_manual
		  water_unit.setNominalCapacity(nominal_capacity_si)
		else
		  water_unit.autosizeNominalCapacity()
		end
		
		water_unit.autosizeDesignWaterFlowRate()
		runner.registerInfo("Final: The Thermal Efficiency for '#{unit_name}' was #{boiler_thermal_efficiency}")
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
		unit_name = steam_unit.name
		thermal_efficiency_old = steam_unit.theoreticalEfficiency()
		if not thermal_efficiency_old.is_a? Numeric
		  runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was not set.")
		else
		  runner.registerInfo("Initial: The Thermal Efficiency for '#{unit_name}' was #{boiler_thermal_efficiency}.")
		end
		
		steam_unit.setNominalThermalEfficiency(boiler_thermal_efficiency)
		
		if is_capacity_manual
		  steam_unit.setNominalCapacity(nominal_capacity_si)
		else
		  steam_unit.autosizeNominalCapacity()
		end
		
		steam_unit.autosizeDesignWaterFlowRate()
		runner.registerInfo("Final: The Thermal Efficiency for '#{unit_name}' was #{boiler_thermal_efficiency}")
		end
	end
  end
  
  #define what happens when the measure is run
  def run(model, runner, user_arguments)
	super(model, runner, user_arguments)

	#use the built-in error checking
	if not runner.validateUserArguments(arguments(model), user_arguments)
	  return false
	end

	# Determine if the measure is applicable to the model, if not just return and no changes are made.
	boiler_bool = runner.getBoolArgumentValue("boiler_bool", user_arguments)
	if boiler_bool
	  runner.registerInfo("This measure is not applicable.")
	  return true
	end

	#assign the user inputs to variables
	boiler_name = runner.getOptionalWorkspaceObjectChoiceValue("boiler_name", user_arguments, model)	
	handle = runner.getStringArgumentValue("boiler_name", user_arguments)
	boiler_index = handle.to_i
	boiler_thermal_efficiency = runner.getDoubleArgumentValue("boiler_thermal_efficiency",user_arguments)
	boiler_outlet_temperature_ip = runner.getDoubleArgumentValue("boiler_outlet_temperature_ip",user_arguments)
	is_capacity_manual = runner.getBoolArgumentValue("is_capacity_manual",user_arguments)
	nominal_capacity_si = runner.getDoubleArgumentValue("nominal_capacity_si",user_arguments)
	
	# Check if input is valid
	if boiler_thermal_efficiency < 0 or boiler_thermal_efficiency > 1
	  runner.registerError("Boiler Thermal Efficiency must be between 0 and 1.")
	  return false
	end
	
	if boiler_outlet_temperature_ip < 0 or boiler_outlet_temperature_ip > 600
  	  runner.registerError("Boiler outlet temperature must be between 0 and 600 F")
	  return false
	end
	
	boiler_outlet_temperature_si = (boiler_outlet_temperature_ip - 32)*(5/9) # si units for boiler temperature argument
	
	changeThermalEfficiency(model, boiler_index, boiler_thermal_efficiency, boiler_outlet_temperature_si, is_capacity_manual, nominal_capacity_si, runner)

    return true
  end # end the run method

end # end the measure

# this allows the measure to be used by the application
SetBoilerThermalEfficiencyAndAutosize.new.registerWithApplication
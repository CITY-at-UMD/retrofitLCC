# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# start the measure
class HardsizeTwoSpeedDXCoolingCoil < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "HardsizeTwoSpeedDXCoolingCoil"
  end

  # human readable description
  def description
    return "This measure reads in information about a two-speed DX cooling coil in an air handling unit from an EnergyPlus output file.  It then sets the values in the model accordingly.  This prevents autosizing of these parameters, so the simulation will capture the proper part-load efficiency if other energy efficiency measures are implemented."
  end

  # human readable description of modelling approach
  def modeler_description
    return "Reads and sets the following parameters for a CoolingCoilDXTwoSpeed object from an EnergyPlus eplusout.eio file:
Rated High Speed Total Cooling Capacity
Rated High Speed Sensible Heat Ratio
Rated High Speed Air Flow Rate
Rated Low Speed Total Cooling Capacity
Rated Low Speed Sensible Heat Ratio
Rated Low Speed Air Flow Rate"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

	# populate choice argument for air loops in the model
    air_loop_handles = OpenStudio::StringVector.new
    air_loop_display_names = OpenStudio::StringVector.new

    # put air loops and names into a hash table
    air_loop_args = model.getAirLoopHVACs
    air_loop_args_hash = {}
    air_loop_args.each do |air_loop_arg|
      air_loop_args_hash[air_loop_arg.name.to_s] = air_loop_arg
    end

    # looping through sorted hash of air loops, and save those with Two Speed Cooling Coils
    air_loop_args_hash.sort.map do |key,value|
	  show_loop = false
	  components = value.supplyComponents
	  components.each do |component|
	    if not component.to_CoilCoolingDXTwoSpeed.is_initialized  #instead of if not component.to_CoilCoolingDXTwoSpeed.empty?
  		  show_loop = true
	    end
	  end
	  if show_loop == true
	    air_loop_handles << value.handle.to_s
	    air_loop_display_names << key
	  end
    end
	
	# add building to string vector to do all air loops
    building = model.getBuilding
    air_loop_handles << building.handle.to_s
    air_loop_display_names << "*All Air Loops*"

    # make an argument for air loops
    object = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("object", air_loop_handles, air_loop_display_names,true)
    object.setDisplayName("Choose an Air Loop with a Two Speed DX Cooling Unit to Alter.")
    object.setDefaultValue("*All Air Loops*") #if no air loop is chosen this will run on all air loops
    args << object	
		
    # the eio filename and location to be used
    eio_fname = OpenStudio::Ruleset::OSArgument.makeStringArgument("eio_fname", true)
    eio_fname.setDescription("Please select the eio file to use for hard-sizing.")
    eio_fname.setDisplayName("eio_fname")   
    args << eio_fname
	
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    object = runner.getOptionalWorkspaceObjectChoiceValue("object",user_arguments,model) # model is passed in because of argument type
	eio_fname = runner.getStringArgumentValue("eio_fname", user_arguments)	
	
	# EIO file path
	coil_sizing_hash = Hash.new
	begin 
      eio_file = File.open(eio_fname,"r")
	rescue
      runner.registerError("#{eio_fname} was not found. Make sure the eio file location is valid.")
	  return false
	else	
      eio_file.each do |line|
        if line.include?" Component Sizing Information, Coil:Cooling:DX:TwoSpeed"
		  a = line.split(", ")
		  key = "#{a[2]}#{a[3]}".upcase # object name, value name, value
		  key = key.gsub("\n", "")
		  # remove units, units in eio file are inside brackets []
          key = key.gsub(/ +\[[a-zA-Z\/1-9\-]*\]/,"")
          # remove () and the contents in (), e.g., (gross)
          key = key.gsub(/ +\([a-zA-Z\/1-9\-]*\)/,"")
          # puts "key: #{a[3]}, value: #{a[4]}, key: #{key}"
          coil_sizing_hash[key] = a[4] 
          end
      end
	  runner.registerInfo("Coil sizing information pulled from #{eio_fname}.")
	end
	hs_cap = "DESIGN SIZE RATED HIGH SPEED TOTAL COOLING CAPACITY"
	hs_shr = "DESIGN SIZE RATED HIGH SPEED SENSIBLE HEAT RATIO"
	hs_afr = "DESIGN SIZE RATED HIGH SPEED AIR FLOW RATE"
	ls_cap = "DESIGN SIZE RATED LOW SPEED TOTAL COOLING CAPACITY"
	ls_shr = "DESIGN SIZE RATED LOW SPEED SENSIBLE HEAT RATIO"
	ls_afr = "DESIGN SIZE RATED LOW SPEED AIR FLOW RATE"

	# check the air_loop for reasonableness
    apply_to_all_air_loops = false
    air_loop = nil
    if object.empty?
      handle = runner.getStringArgumentValue("object",user_arguments)
      if handle.empty?
        runner.registerError("No air loop was chosen.")
      else
        runner.registerError("The selected air_loop with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not object.get.to_AirLoopHVAC.empty?
        air_loop = object.get.to_AirLoopHVAC.get
      elsif not object.get.to_Building.empty?
        apply_to_all_air_loops = true
      else
        runner.registerError("Script Error - argument not showing up as air loop.")
        return false
      end
    end  #end of if air_loop.empty?
	
	# get air loops for measure
    if apply_to_all_air_loops
      air_loops = model.getAirLoopHVACs
    else
      air_loops = []
      air_loops << air_loop # only run on a single air loop
    end
	
    #loop through air loops
    air_loops.each do |air_loop|
      supply_components = air_loop.supplyComponents

      #find two speed dx units on loop
      supply_components.each do |supply_component|
        hVACComponent = supply_component.to_CoilCoolingDXTwoSpeed
        if not hVACComponent.empty?
          hVACComponent = hVACComponent.get

          #change and report variables
          initial_high_cap = hVACComponent.ratedHighSpeedTotalCoolingCapacity
		  if initial_high_cap.empty?
		    initial_high_cap = 'autosize'
		  end
		  initial_high_shr = hVACComponent.ratedHighSpeedSensibleHeatRatio
		  if initial_high_shr.empty?
		    initial_high_shr = 'autosize'
		  end
		  initial_high_afr = hVACComponent.ratedHighSpeedAirFlowRate 
		  if initial_high_afr.empty?
		    initial_high_afr = 'autosize'
		  end
		  initial_high_cop = hVACComponent.ratedHighSpeedCOP
		  initial_low_cap = hVACComponent.ratedLowSpeedTotalCoolingCapacity
		  if initial_low_cap.empty?
		    initial_low_cap = 'autosize'
		  end
		  initial_low_shr = hVACComponent.ratedLowSpeedSensibleHeatRatio
		  if initial_low_shr.empty?
		    initial_low_shr = 'autosize'
		  end
		  initial_low_afr = hVACComponent.ratedLowSpeedAirFlowRate
		  if initial_low_afr.empty?
		    initial_low_afr = 'autosize'
		  end
		  initial_low_cop = hVACComponent.ratedLowSpeedCOP
		  final_high_cap = coil_sizing_hash[hVACComponent.name.to_s.upcase+hs_cap].to_f
		  final_high_shr = coil_sizing_hash[hVACComponent.name.to_s.upcase+hs_shr].to_f
		  final_high_afr = coil_sizing_hash[hVACComponent.name.to_s.upcase+hs_afr].to_f
		  final_low_cap = coil_sizing_hash[hVACComponent.name.to_s.upcase+ls_cap].to_f
		  final_low_shr = coil_sizing_hash[hVACComponent.name.to_s.upcase+ls_shr].to_f
		  final_low_afr = coil_sizing_hash[hVACComponent.name.to_s.upcase+ls_afr].to_f
          runner.registerInfo("*Setting values for Two Speed DX Unit '#{hVACComponent.name}' on air loop '#{air_loop.name}':\nRated High Speed Total Cooling Capacity from '#{initial_high_cap.to_s}' to '#{final_high_cap}'\nRated High Speed Sensible Heat Ratio from '#{initial_high_shr.to_s}' to '#{final_high_shr}'\nRated High Speed Air Flow Rate from '#{initial_high_afr.to_s}' to '#{final_high_afr}'\nRated Low Speed Total Cooling Capacity from '#{initial_low_cap.to_s}' to '#{final_low_cap}'\nRated Low Speed Sensible Heat Ratio from '#{initial_low_shr.to_s}' to '#{final_low_shr}'\nRated Low Speed Air Flow Rate from '#{initial_low_afr.to_s}' to '#{final_low_afr}'.\n")
		  hVACComponent.setRatedHighSpeedTotalCoolingCapacity(OpenStudio::OptionalDouble.new(final_high_cap))
          hVACComponent.setRatedHighSpeedSensibleHeatRatio(OpenStudio::OptionalDouble.new(final_high_shr))
          hVACComponent.setRatedHighSpeedAirFlowRate(OpenStudio::OptionalDouble.new(final_high_afr))
		  hVACComponent.setRatedLowSpeedTotalCoolingCapacity(OpenStudio::OptionalDouble.new(final_low_cap))
          hVACComponent.setRatedLowSpeedSensibleHeatRatio(OpenStudio::OptionalDouble.new(final_low_shr))
          hVACComponent.setRatedLowSpeedAirFlowRate(OpenStudio::OptionalDouble.new(final_low_afr))
		  
        end #end if not hVACComponent.empty?
      end #end supply_components.each do
    end #end air_loops.each do
	
    # report final condition of model
    runner.registerFinalCondition("Two Speed DX Cooling Coils on #{air_loops.size} air loops had their values changed.")

    return true
  end # end the run method  
end # end the measure

# register the measure to be used by the application
HardsizeTwoSpeedDXCoolingCoil.new.registerWithApplication
#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ReduceLPD < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ReduceLPD"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
	
	#populate choices for argument for fans in the model
	light_handles = OpenStudio::StringVector.new
    light_display_names = OpenStudio::StringVector.new
	
	#putting fan names into hash
	light_hash = {}
	model.getLightsDefinitions.each do |light|
	  light_hash[light.name.to_s] = light
	end	
	
	#looping through sorted hash of zones
    light_hash.sort.map do |light_name, light|
      light_handles << light.handle.to_s
      light_display_names << light_name
    end
		
	#make an argument for lights
    light_def = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("light_def", light_display_names, true)
    light_def.setDisplayName("Choose lights definitions to change power density.")
    light_def.setDefaultValue("") #first light def shown
    args << light_def	
	
    #make an argument for the light definition to modify
    new_LPD_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("new_LPD_ip",true)
    new_LPD_ip.setDisplayName("New LPD (W/ft^2):")
    new_LPD_ip.setDefaultValue(0.9)
    args << new_LPD_ip	

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    light_def = runner.getOptionalWorkspaceObjectChoiceValue("light_def",user_arguments,model)
	selected_light = runner.getStringArgumentValue("light_def",user_arguments)
    new_LPD_ip = runner.getDoubleArgumentValue("new_LPD_ip",user_arguments)
	new_LPD_si = OpenStudio::convert(new_LPD_ip,"W/ft^2","W/m^2").to_f
	    	
    # loop through space types
    model.getLightsDefinitions.each do |lightDef|
		puts "#{lightDef.name.to_s} and #{selected_light}"
	
	  if lightDef.name.to_s == selected_light
	    initial_LPD = lightDef.wattsperSpaceFloorArea() 
		
		initial_LPD_ip = initial_LPD.to_f * (1/OpenStudio::convert(1,"W/ft^2","W/m^2").to_f)
		
		#reporting initial LPD of lights
		runner.registerInitialCondition("The light definition #{lightDef.name.to_s} started with #{initial_LPD_ip}(W/ft^2).")
	
		lightDef.setWattsperSpaceFloorArea(new_LPD_si)
		
		#reporting final LPD of lights
		runner.registerFinalCondition("The light definition #{lightDef.name.to_s} finished with #{new_LPD_ip}(W/ft^2).")
	  end

    end # end of lightDefs each do

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ReduceLPD.new.registerWithApplication
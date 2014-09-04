#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#Query the user to select reporting frequency, and which fuel factors to use.
#TODO fuel factor selection data
#   generate regional water consumption (defaulting to U.S. avg for Eastern and Western Electricity Fuel Factors, using Texas data for ERCOT)
#	add per-state selection of electricity fuel factors
#   add FuelFactors for less common fuels
# 	add FuelFactors for other combustion equipment 
# 	add multiple fuel factors depending on equipment type. this is difficult.
#TODO	Remove all existing environmental impact factors
#   this is difficult to do in workspace, and not likely necessary.  Skipping for first version

#References:
#  EnergyPlus Input/Output Reference, p.2086
#  EnergyPlus Engineering Reference, p.1382&
#  M. Deru and P. Torcellini, "Source Energy and Emission Factors for Energy Use in Buildings", June 2007.  Technical Report NREL/tP-550-38617.  Available at: http://www.nrel.gov/docs/fy07osti/38617.pdf
#  Torcellini Paul A, Nicholas Long, and Ronald D. Judkoff. 2004. “Consumptive Water Use for U.S. Power Production,” in ASHRAE Transactions, Volume 110, Part 1. Atlanta, Georgia: ASHRAE.

#Notes: Coal is treated as Bituminous Coal, FuelOil#1 and FuelOil#2 are both treated as Distillate Fuel Oil

#start the measure
class AddEnvironmentalImpactFactors < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddEnvironmentalImpactFactors"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # make a user choice for the reporting frequency
    reporting_frequency_chs = OpenStudio::StringVector.new    
    reporting_frequency_chs << "Timestep"
    reporting_frequency_chs << "Hourly"
    reporting_frequency_chs << "Daily"
    reporting_frequency_chs << "Monthly"
	reporting_frequency_chs << "RunPeriod"
    reporting_frequency = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('reporting_frequency', reporting_frequency_chs, true)
    reporting_frequency.setDisplayName("Reporting Frequency:")
    reporting_frequency.setDefaultValue("RunPeriod")
    args << reporting_frequency 

	# make a user choice for the electricity region
    electricity_region_chs = OpenStudio::StringVector.new    
    electricity_region_chs << "National"
    electricity_region_chs << "Eastern"
    electricity_region_chs << "Western"
    electricity_region_chs << "ERCOT"
	electricity_region_chs << "Alaska"
	electricity_region_chs << "Hawaii"
    electricity_region = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('electricity_region', electricity_region_chs, true)
    electricity_region.setDisplayName("Electricity Region:")
    electricity_region.setDefaultValue("National")
    args << electricity_region	
	
	# make a user choice for the equipment type
    equipment_chs = OpenStudio::StringVector.new    
    equipment_chs << "Commercial Boiler"
	#not yet available; add .idf files 
    #equipment_chs << "Stationary Reciprocating Engine"
    #equipment_chs << "Small Turbine"
    #equipment_chs << "Residential Furnace"
    equipment = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('equipment', equipment_chs, true)
    equipment.setDisplayName("Equipment Type for Fuel Factors:")
    equipment.setDefaultValue("Commercial Boiler")
    args << equipment	
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    #assign the user inputs to variables
	reporting_frequency = runner.getStringArgumentValue("reporting_frequency",user_arguments) 
	electricity_region = runner.getStringArgumentValue("electricity_region",user_arguments) 
	equipment = runner.getStringArgumentValue("equipment",user_arguments) 
	
	#make a new Output:EnvironmentalImpactFactors object from a string
    new_output_string = "
      Output:EnvironmentalImpactFactors,
        #{reporting_frequency};    !- Reporting Frequency
      "
    idfObject = OpenStudio::IdfObject::load(new_output_string)
    object = idfObject.get
    wsObject = workspace.addObject(object)
    new_string = wsObject.get
    runner.registerInfo("Added Output:EnvironmentalImpactFactors object with a value of #{new_string.getString(0)}")
	  
	#make a new EnvironmentalImpactFactors object from a string
	#Carbon Equivalents from http://www.ipcc.ch/publications_and_data/ar4/wg1/en/ch2s2-10-2.html, based on 100-yr time horizon
    new_output_string = "
	  EnvironmentalImpactFactors,
		0.3,                     !- District Heating Efficiency
		3,                       !- District Cooling COP {W/W}
		0.25,                    !- Steam Conversion Efficiency
		81.3306,                 !- Total Carbon Equivalent Emission Factor From N2O {kg/kg}
		6.8230,                  !- Total Carbon Equivalent Emission Factor From CH4 {kg/kg}
		0.2729;                  !- Total Carbon Equivalent Emission Factor From CO2 {kg/kg}
	  "
    idfObject = OpenStudio::IdfObject::load(new_output_string)
    object = idfObject.get
    workspace.addObject(object)
    runner.registerInfo("Added EnvironmentalImpactFactors object")	  
	  
	#load the idf file containing the electricity fuel factors from resources folder
	electricity_filename = "Electricity_#{electricity_region}_FuelFactors.idf"
    electricity_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/#{electricity_filename}")
    electricity_file = OpenStudio::IdfFile::load(electricity_path)
    #in OpenStudio PAT in 1.1.0 and earlier all resource files are moved up a directory.
    #below is a temporary workaround for this before issuing an error.
    if electricity_file.empty?
      electricity_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{electricity_filename}")
      electricity_file = OpenStudio::IdfFile::load(electricity_path)
    end
    if electricity_file.empty?
      runner.registerError("Unable to find the file #{electricity_filename}")
      return false
    else
      electricity_file = electricity_file.get
    end
    # add to the workspace
    workspace.addObjects(electricity_file.getObjectsByType("FuelFactors".to_IddObjectType)).each do |object|	
      runner.registerInfo("Added FuelFactors object for #{object.getString(0)}")
	end
	
	#load the idf file containing the natural gas fuel factors from resources folder
	natural_gas_filename = "Natural Gas_#{equipment}_FuelFactors.idf"
    natural_gas_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/#{natural_gas_filename}")
    natural_gas_file = OpenStudio::IdfFile::load(natural_gas_path)
    #in OpenStudio PAT in 1.1.0 and earlier all resource files are moved up a directory.
    #below is a temporary workaround for this before issuing an error.
    if natural_gas_file.empty?
      natural_gas_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{natural_gas_filename}")
      natural_gas_file = OpenStudio::IdfFile::load(natural_gas_path)
    end
    if natural_gas_file.empty?
      runner.registerError("Unable to find the file #{natural_gas_filename}")
      return false
    else
      natural_gas_file = natural_gas_file.get
    end
    # add to the workspace
    workspace.addObjects(natural_gas_file.getObjectsByType("FuelFactors".to_IddObjectType)).each do |object|	
      runner.registerInfo("Added FuelFactors object for #{object.getString(0)}")
	end
	
    #reporting final condition of model
    finishing_objects = []
	finishing_objects << workspace.getObjectsByType("Output:EnvironmentalImpactFactors".to_IddObjectType)
	finishing_objects << workspace.getObjectsByType("EnvironmentalImpactFactors".to_IddObjectType)
	finishing_objects << workspace.getObjectsByType("FuelFactors".to_IddObjectType)
    runner.registerFinalCondition("The model finished with #{finishing_objects[0].size} Output:EnvironmentalImpactFactors objects, #{finishing_objects[1].size} EnvironmentalImpactFactors objects, and #{finishing_objects[2].size} FuelFactor objects.")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddEnvironmentalImpactFactors.new.registerWithApplication
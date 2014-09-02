#see the URL below for information on how to write OpenStuido measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#Query the user to select tariffs for consideration 

#start the measure
class AddUtilityRates < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddUtilityRates"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new
 
    #make an argument for the electric tariff
    elec_chs = OpenStudio::StringVector.new
    elec_chs << "PECO Rates"
    elec_tar = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('elec_tar', elec_chs, true)
    elec_tar.setDisplayName("Select an Electricity Tariff.")
    elec_tar.setDefaultValue("PECO Rates")
    args << elec_tar
    
    #make an argument for the gas tariff
    gas_chs = OpenStudio::StringVector.new    
    gas_chs << "PGW Rates" 
    gas_tar = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('gas_tar', gas_chs, true)
    gas_tar.setDisplayName("Select a Gas Tariff.")
    gas_tar.setDefaultValue("PGW Rates")
    args << gas_tar
    
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
    elec_tar = runner.getStringArgumentValue("elec_tar",user_arguments)
    gas_tar = runner.getStringArgumentValue("gas_tar",user_arguments)

    #import the tariffs
    [elec_tar,gas_tar].each do |tar|
    
      #load the idf file containing the electric tariff
      tar_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/#{tar}.idf")
      tar_file = OpenStudio::IdfFile::load(tar_path)

      #in OpenStudio PAT in 1.1.0 and earlier all resource files are moved up a directory.
      #below is a temporary workaround for this before issuing an error.
      if tar_file.empty?
        tar_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{tar}.idf")
        tar_file = OpenStudio::IdfFile::load(tar_path)
      end

      if tar_file.empty?
        runner.registerError("Unable to find the file #{tar}.idf")
        return false
      else
        tar_file = tar_file.get
      end
  
      #add the tariffs
      workspace.addObjects(tar_file.getObjectsByType("UtilityCost:Tariff".to_IddObjectType))
      
      #add the simple charges
      workspace.addObjects(tar_file.getObjectsByType("UtilityCost:Charge:Simple".to_IddObjectType))
      
      #add the block charges
      workspace.addObjects(tar_file.getObjectsByType("UtilityCost:Charge:Block".to_IddObjectType))
    
      #let the user know what happened
      runner.registerInfo("added a tariff named #{tar}")    
    end
	   
    #set the simulation timestep to 15min (4 per hour) to match the demand window of the tariffs
    if not workspace.getObjectsByType("Timestep".to_IddObjectType).empty?
      workspace.getObjectsByType("Timestep".to_IddObjectType)[0].setString(0,"4")
      runner.registerInfo("set the simulation timestep to 15 min to match the demand window of the tariffs")
    else
      runner.registerError("there was no timestep object to alter")
    end
    
    #remove any existing lifecycle cost parameters
    workspace.getObjectsByType("LifeCycleCost:Parameters".to_IddObjectType).each do |object|
      runner.registerInfo("removed existing lifecycle parameters named #{object.name}")
      workspace.removeObjects([object.handle])
    end
    
    #and replace with the FEMP ones
    life_cycle_params_string = "    
    LifeCycleCost:Parameters,
      FEMP LifeCycle Cost Parameters,         !- Name
      EndOfYear,                              !- Discounting Convention
      ConstantDollar,                         !- Inflation Approach
      0.03,                                   !- Real Discount Rate
      ,                                       !- Nominal Discount Rate
      ,                                       !- Inflation
      ,                                       !- Base Date Month
      2013,                                   !- Base Date Year
      ,                                       !- Service Date Month
      2013,                                   !- Service Date Year
      20,                                     !- Length of Study Period in Years
      ,                                       !- Tax rate
      None;                                   !- Depreciation Method	  
    "  
    life_cycle_params = OpenStudio::IdfObject::load(life_cycle_params_string).get
    workspace.addObject(life_cycle_params)
    runner.registerInfo("added lifecycle cost parameters named #{life_cycle_params.name}")
  
  
    #remove any existing lifecycle cost parameters
    workspace.getObjectsByType("LifeCycleCost:UsePriceEscalation".to_IddObjectType).each do |object|
      runner.registerInfo("removed existing fuel escalation rates named #{object.name}")
      workspace.removeObjects([object.handle])
    end  
  
    elec_escalation_string = "
	LifeCycleCost:UsePriceEscalation,
		NIST_COMMERCIAL_ELECTRICITY, !- Name
		Electricity,             !- Resource
		2013,                    !- Escalation Start Year
		April,                   !- Escalation Start Month
		0.98,                    !- Year 1 Escalation
		0.96,                    !- Year 2 Escalation
		0.96,                    !- Year 3 Escalation
		0.97,                    !- Year 4 Escalation
		0.98,                    !- Year 5 Escalation
		0.99,                    !- Year 6 Escalation
		0.98,                    !- Year 7 Escalation
		0.98,                    !- Year 8 Escalation
		0.98,                    !- Year 9 Escalation
		0.98,                    !- Year 10 Escalation
		0.99,                    !- Year 11 Escalation
		0.98,                    !- Year 12 Escalation
		0.95,                    !- Year 13 Escalation
		0.95,                    !- Year 14 Escalation
		0.97,                    !- Year 15 Escalation
		0.97,                    !- Year 16 Escalation
		0.98,                    !- Year 17 Escalation
		0.98,                    !- Year 18 Escalation
		0.99,                    !- Year 19 Escalation
		1.00,                    !- Year 20 Escalation
		1.00,                    !- Year 21 Escalation
		1.01,                    !- Year 22 Escalation
		1.02,                    !- Year 23 Escalation
		1.03,                    !- Year 24 Escalation
		1.05,                    !- Year 25 Escalation
		1.08,                    !- Year 26 Escalation
		1.09,                    !- Year 27 Escalation
		1.10,                    !- Year 28 Escalation
		1.11,                    !- Year 29 Escalation
		1.11;                    !- Year 30 Escalation
    "
    elec_escalation = OpenStudio::IdfObject::load(elec_escalation_string).get
    workspace.addObject(elec_escalation)  
    runner.registerInfo("added fuel escalation rates named #{elec_escalation.name}")    
      
    nat_gas_escalation_string = "
	LifeCycleCost:UsePriceEscalation,
		NIST_COMMERCIAL_GAS, !- Name
		Gas,                     !- Resource
		2013,                    !- Escalation Start Year
		April,                   !- Escalation Start Month
		0.99,                    !- Year 1 Escalation
		0.97,                    !- Year 2 Escalation
		1.00,                    !- Year 3 Escalation
		1.02,                    !- Year 4 Escalation
		1.05,                    !- Year 5 Escalation
		1.07,                    !- Year 6 Escalation
		1.08,                    !- Year 7 Escalation
		1.09,                    !- Year 8 Escalation
		1.11,                    !- Year 9 Escalation
		1.12,                    !- Year 10 Escalation
		1.13,                    !- Year 11 Escalation
		1.14,                    !- Year 12 Escalation
		1.16,                    !- Year 13 Escalation
		1.17,                    !- Year 14 Escalation
		1.18,                    !- Year 15 Escalation
		1.19,                    !- Year 16 Escalation
		1.20,                    !- Year 17 Escalation
		1.21,                    !- Year 18 Escalation
		1.22,                    !- Year 19 Escalation
		1.24,                    !- Year 20 Escalation
		1.26,                    !- Year 21 Escalation
		1.28,                    !- Year 22 Escalation
		1.31,                    !- Year 23 Escalation
		1.34,                    !- Year 24 Escalation
		1.38,                    !- Year 25 Escalation
		1.40,                    !- Year 26 Escalation
		1.42,                    !- Year 27 Escalation
		1.45,                    !- Year 28 Escalation
		1.47,                    !- Year 29 Escalation
		1.50;                    !- Year 30 Escalation
    "
    nat_gas_escalation = OpenStudio::IdfObject::load(nat_gas_escalation_string).get
    workspace.addObject(nat_gas_escalation) 
    runner.registerInfo("added fuel escalation rates named #{nat_gas_escalation.name}")     
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddUtilityRates.new.registerWithApplication










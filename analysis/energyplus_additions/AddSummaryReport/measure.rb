#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#Query the user to select which reports to include
#TODO add 12 pages of report options from I/O reference as check boxes

#start the measure
class AddSummaryReport < OpenStudio::Ruleset::WorkspaceUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddSummaryReport"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # make a user choice for the reporting frequency
    reports_request_chs = OpenStudio::StringVector.new
    reports_request_chs << "AllSummary"
    reports_request_chs << "AllMonthly"
    reports_request_chs << "AllSummaryAndMonthly"
    reports_request_chs << "AllSummaryAndSizingPeriod"
	reports_request_chs << "AllSummaryMonthlyAndSizingPeriod"
	reports_request_chs << "ZoneComponentLoadSummary"
    reports_request = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('reports_request', reports_request_chs, true)
    reports_request.setDisplayName("Select Summary Report to Add:")
    reports_request.setDefaultValue("AllSummaryAndSizingPeriod")
    args << reports_request 
	
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
	reports_request = runner.getStringArgumentValue("reports_request",user_arguments) 
	
	#search for Output:Table:SummaryReports object in .idf and remove it
    starting_objects = workspace.getObjectsByType("Output:Table:SummaryReports".to_IddObjectType)
    runner.registerInitialCondition("The model started with #{starting_objects.size} Output:Table:SummaryReports objects.")
	
	#loop through existing objects to see if value of any already matches the requested value.
    object_exists = false
    starting_objects.each do |object|
      if object.getString(0).to_s == reports_request
        object_exists = true
      end
    end

    #adding a new Output:Diagnostic object of requested value if it doesn't already exist
    if object_exists == false
	
	  if starting_objects.size == 0
	    #make a Output:Table:SummaryReports object
        new_report_string = "
		  Output:Table:SummaryReports,
          #{reports_request};    !- Key 1
        "
        idfObject = OpenStudio::IdfObject::load(new_output_string)
        object = idfObject.get
        wsObject = workspace.addObject(object)
        new_object = wsObject.get
        runner.registerInfo("Added Output:Table:SummaryReports object with a value of #{new_object.getString(0)}")
		runner.registerFinalCondition("The model finished adding the Output:Table:SummaryReports Object")	
      else 	  
	    #Output:Table:SummaryReports object already exists
	    starting_object = starting_objects[0]
		index_num = starting_object.numFields()
		new_object = starting_object.setString(1, reports_request)
		runner.registerInfo("Added #{reports_request} to the Output:Table:SummaryReports object")
		runner.registerFinalCondition("The model finished modifying the Output:Table:SummaryReports Object")		
	  end	  
    else
      runner.registerAsNotApplicable("An Output:Table:SummaryReports object with a value of #{reports_request} already existed in your model. Nothing was changed.")
      return true
	end #end of if object_exists == false

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddSummaryReport.new.registerWithApplication
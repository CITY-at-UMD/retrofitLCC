class RunManagerWatcher_Test < MiniTest::Test
def test_RunManagerWatcher

# load OSM file
translator = OpenStudio::OSVersion::VersionTranslator.new
model_path = OpenStudio::Path.new("#{Dir.pwd}/model/Bldg101_StagingPreSetback.osm")
model = translator.loadModel(model_path)
model = model.get 

# load weather file
epw = OpenStudio::Path.new("#{Dir.pwd}/weather/USA_PA_Philadelphia.Intl.AP.724080_TMY3.epw") # set epw file location

 # make a new workflow
wf = OpenStudio::Runmanager::Workflow.new()

# create an instance of a runner
runner = OpenStudio::Ruleset::OSRunner.new
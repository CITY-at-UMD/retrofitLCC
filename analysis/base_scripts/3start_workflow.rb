class RunManagerWatcher_Test < MiniTest::Test
def test_RunManagerWatcher

# configure logging
model = OpenStudio::Path.new("#{Dir.pwd}/model/Bldg101_StagingPreSetback.osm") # load osm file
epw = OpenStudio::Path.new("#{Dir.pwd}/weather/USA_PA_Philadelphia.Intl.AP.724080_TMY3.epw") # set epw file location
wf = OpenStudio::Runmanager::Workflow.new()  # make a new workflow
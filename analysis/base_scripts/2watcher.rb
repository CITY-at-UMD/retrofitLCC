#watcher
class RunManagerWatcherImpl < OpenStudio::Runmanager::RunManagerWatcher
  def initialize(runmanager)
  super
    @m_finishedCounts=[]
  end

  def finishedCounts
    return @m_finishedCounts
  end

  def jobFinishedDetails(t_jobId, t_jobType, t_lastRun, t_errors, t_outputFiles, t_inputParams, t_isMergedJob, t_mergedIntoJobId)
    puts "\n'#{t_jobType.valueName}' finished\nRUN TIME:#{t_lastRun}\nPARAMS SIZE:#{t_inputParams.params.size}\nMERGED JOB?:#{t_isMergedJob}\n#{t_outputFiles.files.size} output files at: #{t_outputFiles.files.at(0).fullPath}\nJOB FINISHED WITH NO ERRORS?:#{t_errors.succeeded}\nINFO:#{t_errors.infos}\nInitialConditions:#{t_errors.initialConditions}\nFinalConditions:#{t_errors.finalConditions}\nWarnings:#{t_errors.warnings}\nERRORS:#{t_errors.errors}\n"
	#{t_jobId}
	#{t_mergedIntoJobId}
	
    if not @m_finishedCounts[t_jobType.value]
      @m_finishedCounts[t_jobType.value] = 1
    else
      @m_finishedCounts[t_jobType.value] += 1
    end
  end

  def treeFinished(t_job)
    puts "\nJob Tree Finished"
    if not @m_finishedCounts[999]
      @m_finishedCounts[999] = 1
    else
      @m_finishedCounts[999] += 1
    end
  end
  
end
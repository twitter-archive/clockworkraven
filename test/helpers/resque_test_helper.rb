module ResqueTestHelper
  # Mocks out Resque::Plugins::Status::Hash so it returns the given status
  # (as an OpenStruct) when asks for the UUID job.resque_job
  def mock_status job, status
    Resque::Plugins::Status::Hash.expects(:get).
                                  with(job.resque_job).
                                  returns((OpenStruct.new(status) if status))
  end
end
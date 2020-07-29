class ResqueWorker
  @queue = :crash

  def self.perform
    raise 'broken'
  end
end

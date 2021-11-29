class ResqueWorker
  @queue = :crash

  def self.perform(*arguments, **named_arguments)
    raise 'broken'
  end
end

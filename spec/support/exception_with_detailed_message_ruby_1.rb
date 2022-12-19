# ExceptionWithDetailedMessage for Ruby 1.9 (no keyword argument)
class ExceptionWithDetailedMessage < Exception
  def detailed_message(params)
    # change the output to ensure we pass the right value for "highlight"
    if params[:highlight]
      "\e[1m!!! #{self} !!!\e[0m"
    else
      "#{self} with some extra detail"
    end
  end
end

class ExceptionWithDetailedMessage < Exception
  def detailed_message(highlight: true)
    # change the output to ensure we pass the right value for "highlight"
    if highlight
      "\e[1m!!! #{self} !!!\e[0m"
    else
      "#{self} with some extra detail"
    end
  end
end

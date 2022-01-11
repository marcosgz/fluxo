module ConfigHelpers
  def reset_config!
    Floop.instance_variable_set(:@config, nil)
  end
end

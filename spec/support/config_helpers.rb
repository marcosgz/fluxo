module ConfigHelpers
  def reset_config!
    Fluxo.instance_variable_set(:@config, nil)
  end
end

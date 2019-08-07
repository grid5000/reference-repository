# coding: utf-8

class GPURef
  @@gpu2cores = {
    "GeForce RTX 2080 Ti" => 4352,
    "GeForce GTX 1080 Ti" => 3584,
    "Tesla P100-PCIE-16GB" => 3584,
    "Tesla V100-PCIE-32GB" => 5120,
    "Tesla M2075" => 448,
    "GeForce GTX TITAN Black" => 2880,
    "GeForce GTX 980" => 2048,
    "Tesla K40m" => 2880,
  }

  @@new_gpu_names2old_ones = {
    "GeForce RTX 2080 Ti" => "RTX 2080 Ti",
    "GeForce GTX 1080 Ti" => "GTX 1080 Ti",
    "Tesla P100-PCIE-16GB" => "Tesla P100",
    "Tesla V100-PCIE-32GB" => "Tesla V100",
    "Tesla M2075" => "Tesla M2075",
    "GeForce GTX TITAN Black" => "Titan Black",
    "GeForce GTX 980" => "GTX 980",
    "Tesla K40m" => "Tesla K40M",
  }

  def self.getNumberOfCoresFor(model)
    if @@gpu2cores[model]
      return @@gpu2cores[model]
    else
      raise "Fix me: #{model} is missing"
    end
  end

  # will not keep this, just to ease manual testing for bug #10436
  def self.getGrid5000LegacyNameFor(model)
    if @@new_gpu_names2old_ones[model]
      return @@new_gpu_names2old_ones[model]
    else
      return model
    end
  end

end


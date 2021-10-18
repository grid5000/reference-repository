# coding: utf-8

class GPURef
  @@gpu2cores = {
    "GeForce RTX 2080 Ti" => 4352,
    "GeForce GTX 1080 Ti" => 3584,
    "Tesla P100-PCIE-16GB" => 3584,
    "Tesla P100-SXM2-16GB" => 3584,
    "Tesla V100-PCIE-32GB" => 5120,
    "Tesla V100-SXM2-32GB" => 5120,
    "Tesla M2075" => 448,
    "GeForce GTX TITAN Black" => 2880,
    "GeForce GTX 980" => 2048,
    "Tesla K40m" => 2880,
    "Tesla T4" => 2560,
    "A100-PCIE-40GB" => 6912,
    "A40" => 10752,
    "Quadro RTX 6000" => 4608,
    "Radeon Instinct MI50 32GB" => 5120,
  }

  @@model2sname = {
    "GeForce RTX 2080 Ti" => "RTX 2080 Ti",
    "GeForce GTX 1080 Ti" => "GTX 1080 Ti",
    "Tesla P100-PCIE-16GB" => "Tesla P100",
    "Tesla P100-SXM2-16GB" => "Tesla P100",
    "Tesla V100-PCIE-32GB" => "Tesla V100",
    "Tesla V100-SXM2-32GB" => "Tesla V100",
    "Tesla M2075" => "Tesla M2075",
    "GeForce GTX TITAN Black" => "Titan Black",
    "GeForce GTX 980" => "GTX 980",
    "Tesla K40m" => "Tesla K40M",
    "Tesla T4" => "Tesla T4",
    "A100-PCIE-40GB" => "A100",
    "A40" => "A40",
    "Quadro RTX 6000" => "Quadro RTX 6000",
    "Radeon Instinct MI50 32GB" => "MI50"
  }

  def self.getNumberOfCoresFor(model)
    if @@gpu2cores[model]
      return @@gpu2cores[model]
    else
      raise "Fix me: #{model} is missing"
    end
  end

  # will not keep this, just to ease manual testing for bug #10436
  def self.model2shortname(model)
    if @@model2sname[model]
      return @@model2sname[model]
    else
      raise "Missing short name for model: #{model}"
    end
  end

end

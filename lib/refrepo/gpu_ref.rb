# coding: utf-8

class GPURef
  @@gpus = {
    'GeForce RTX 2080 Ti' => {
      'cores'              => 4352,
      'compute_capability' => '7.5',
      'short_name'         => 'RTX 2080 Ti',
    },
    'GeForce GTX 1080 Ti' => {
      'cores'              => 3584,
      'compute_capability' => '6.1',
      'short_name'         => 'GTX 1080 Ti',
    },
    'Tesla P100-PCIE-16GB' => {
      'cores'              => 3584,
      'compute_capability' => '6.0',
      'short_name'         => 'Tesla P100',
    },
    'Tesla P100-SXM2-16GB' => {
      'cores'              => 3584,
      'compute_capability' => '6.0',
      'short_name'         => 'Tesla P100',
    },
    'Tesla V100-PCIE-32GB' => {
      'cores'              => 5120,
      'compute_capability' => '7.0',
      'short_name'         => 'Tesla V100',
    },
    'Tesla V100-SXM2-32GB' => {
      'cores'              => 5120,
      'compute_capability' => '7.0',
      'short_name'         => 'Tesla V100',
    },
    'Tesla M2075' => {
      'cores'              => 448,
      'compute_capability' => '2.0',
      'short_name'         => 'Tesla M2075',
    },
    'GeForce GTX 980' => {
      'cores'              => 2048,
      'compute_capability' => '5.2',
      'short_name'         => 'GTX 980',
    },
    'Tesla K40m' => {
      'cores'              => 2880,
      'compute_capability' => '3.5',
      'short_name'         => 'Tesla K40M',
    },
    'Tesla T4' => {
      'cores'              => 2560,
      'compute_capability' => '7.5',
      'short_name'         => 'Tesla T4',
    },
    'A100-PCIE-40GB' => {
      'cores'              => 6912,
      'compute_capability' => '8.0',
      'short_name'         => 'A100',
    },
    'A40' => {
      'cores'              => 10752,
      'compute_capability' => '8.6',
      'short_name'         => 'A40',
    },
    'Quadro RTX 6000' => {
      'cores'              => 4608,
      'compute_capability' => '7.5',
      'short_name'         => 'Quadro RTX 6000',
    },
    'Radeon Instinct MI50 32GB' => {
      'cores'              => 5120,
      'short_name'         => 'MI50',
    },
  }

  def self.getNumberOfCoresFor(model)
    if @@gpus[model]
      return @@gpus[model]['cores']
    else
      raise "Fix me: #{model} is missing"
    end
  end

  def self.model2shortname(model)
    if @@gpus[model]
      return @@gpus[model]['short_name']
    else
      raise "Missing short name for model: #{model}"
    end
  end

  def self.get_compute_capability(model)
    if @@gpus[model]
        return @@gpus[model]['compute_capability'] || nil
    else
      raise "Fix me: #{model} is missing"
    end
  end

end

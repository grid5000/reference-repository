# coding: utf-8

class GPURef
  @@gpus = {
    'GeForce RTX 2080 Ti' => {
      'cores'              => 4352,
      'compute_capability' => '7.5',
      'micro_architecture' => 'Turing',
      'short_name'         => 'RTX 2080 Ti',
      'alias'              => 'rtx2080ti',
    },
    'GeForce GTX 1080 Ti' => {
      'cores'              => 3584,
      'compute_capability' => '6.1',
      'micro_architecture' => 'Pascal',
      'short_name'         => 'GTX 1080 Ti',
      'alias'              => 'gtx1080ti',
    },
    'Tesla P100-PCIE-16GB' => {
      'cores'              => 3584,
      'compute_capability' => '6.0',
      'micro_architecture' => 'Pascal',
      'short_name'         => 'Tesla P100',
      'alias'              => 'p100-pcie-16',
    },
    'Tesla P100-SXM2-16GB' => {
      'cores'              => 3584,
      'compute_capability' => '6.0',
      'micro_architecture' => 'Pascal',
      'short_name'         => 'Tesla P100',
      'alias'              => 'p100-sxm2-16',
    },
    'Tesla V100-PCIE-32GB' => {
      'cores'              => 5120,
      'compute_capability' => '7.0',
      'micro_architecture' => 'Volta',
      'short_name'         => 'Tesla V100',
      'alias'              => 'v100-pcie-32',
    },
    'Tesla V100-SXM2-32GB' => {
      'cores'              => 5120,
      'compute_capability' => '7.0',
      'micro_architecture' => 'Volta',
      'short_name'         => 'Tesla V100',
      'alias'              => 'v100-sxm2-32',
    },
    'Tesla M2075' => {
      'cores'              => 448,
      'compute_capability' => '2.0',
      'micro_architecture' => 'Fermi',
      'short_name'         => 'Tesla M2075',
      'alias'              => 'm2075',
    },
    'GeForce GTX 980' => {
      'cores'              => 2048,
      'compute_capability' => '5.2',
      'micro_architecture' => 'Maxwell',
      'short_name'         => 'GTX 980',
      'alias'              => 'gtx980',
    },
    'Tesla K40m' => {
      'cores'              => 2880,
      'compute_capability' => '3.5',
      'micro_architecture' => 'Kepler',
      'short_name'         => 'Tesla K40M',
      'alias'              => 'k40m',
    },
    'Tesla T4' => {
      'cores'              => 2560,
      'compute_capability' => '7.5',
      'micro_architecture' => 'Turing',
      'short_name'         => 'Tesla T4',
      'alias'              => 't4',
    },
    'A100-PCIE-40GB' => {
      'cores'              => 6912,
      'compute_capability' => '8.0',
      'micro_architecture' => 'Ampere',
      'short_name'         => 'A100',
      'alias'              => 'a100-pcie-40',
    },
    'A100-SXM4-40GB' => {
      'cores'              => 6912,
      'compute_capability' => '8.0',
      'micro_architecture' => 'Ampere',
      'short_name'         => 'A100',
      'alias'              => 'a100-sxm4-40',
    },
    'A40' => {
      'cores'              => 10752,
      'compute_capability' => '8.6',
      'micro_architecture' => 'Ampere',
      'short_name'         => 'A40',
      'alias'              => 'a40',
    },
    'Quadro RTX 6000' => {
      'cores'              => 4608,
      'compute_capability' => '7.5',
      'micro_architecture' => 'Turing',
      'short_name'         => 'Quadro RTX 6000',
      'alias'              => 'rtx6000',
    },
    'Radeon Instinct MI50 32GB' => {
      'cores'              => 5120,
      'short_name'         => 'MI50',
      'alias'              => 'mi50-32',
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

  def self.get_micro_architecture(model)
    if @@gpus[model]
        return @@gpus[model]['micro_architecture'] || nil
    else
      raise "Fix me: #{model} is missing"
    end
  end

  def self.get_all_aliases
    aliases = {}
    @@gpus.each do |model, data|
      raise "Fix me: alias is missing for #{model}" unless data['alias']
      aliases[data['alias']] = model
    end

    aliases
  end
end

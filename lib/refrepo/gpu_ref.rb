# coding: utf-8

NVIDIA = 'Nvidia'
MINIMAL_COMPUTE_CAPABILITY_SUPPORTED = 5.2

# Sources to fill this data:
# - https://en.wikipedia.org/wiki/List_of_Nvidia_graphics_processing_units
# - https://www.techpowerup.com/gpu-specs/
class GPURef
  @@gpus = {
    'GeForce RTX 2080 Ti' => {
      'cores'              => 4352,
      'compute_capability' => '7.5',
      'short_name'         => 'RTX 2080 Ti',
      'alias'              => 'rtx2080ti',
      'microarchitecture'  => 'Turing',
      'performance'        => {
        'fp-16' => 26900000000000,
        'fp-32' => 13450000000000,
        'fp-64' => 420000000000,
      },
    },
    'GeForce GTX 1080' => {
      'cores'              => 2560,
      'compute_capability' => '6.1',
      'short_name'         => 'GTX 1080',
      'alias'              => 'gtx1080',
      'microarchitecture'  => 'Pascal',
      'performance'        => {
        'fp-16' => 138600000000,
        'fp-32' => 8872000000000,
        'fp-64' => 277200000000,
      },
    },
    'GeForce GTX 1080 Ti' => {
      'cores'              => 3584,
      'compute_capability' => '6.1',
      'short_name'         => 'GTX 1080 Ti',
      'alias'              => 'gtx1080ti',
      'microarchitecture'  => 'Pascal',
      'performance'        => {
        'fp-16' => 177200000000,
        'fp-32' => 11340000000000,
        'fp-64' => 354400000000,
      },
    },
    'Tesla P100-PCIE-16GB' => {
      'cores'              => 3584,
      'compute_capability' => '6.0',
      'short_name'         => 'Tesla P100',
      'alias'              => 'p100-pcie-16',
      'microarchitecture'  => 'Pascal',
      'performance'        => {
        'fp-16' => 19050000000000,
        'fp-32' => 9526000000000,
        'fp-64' => 4763000000000,
      },
    },
    'Tesla P100-SXM2-16GB' => {
      'cores'              => 3584,
      'compute_capability' => '6.0',
      'short_name'         => 'Tesla P100',
      'alias'              => 'p100-sxm2-16',
      'microarchitecture'  => 'Pascal',
      'performance'        => {
        'fp-16' => 21220000000000,
        'fp-32' => 10610000000000,
        'fp-64' => 5304000000000,
      },
    },
    'Tesla V100-PCIE-16GB' => {
      'cores'              => 5120,
      'compute_capability' => '7.0',
      'short_name'         => 'Tesla V100',
      'alias'              => 'v100-pcie-16',
      'microarchitecture'  => 'Volta',
      'performance'        => {
        'fp-16' => 28260000000000,
        'fp-32' => 14130000000000,
        'fp-64' => 7066000000000,
      },
    },
    'Tesla V100-PCIE-32GB' => {
      'cores'              => 5120,
      'compute_capability' => '7.0',
      'short_name'         => 'Tesla V100',
      'alias'              => 'v100-pcie-32',
      'microarchitecture'  => 'Volta',
      'performance'        => {
        'fp-16' => 28260000000000,
        'fp-32' => 14130000000000,
        'fp-64' => 7066000000000,
      },
    },
    'Tesla V100-SXM2-32GB' => {
      'cores'              => 5120,
      'compute_capability' => '7.0',
      'short_name'         => 'Tesla V100',
      'alias'              => 'v100-sxm2-32',
      'microarchitecture'  => 'Volta',
      'performance'        => {
        'fp-16' => 28260000000000,
        'fp-32' => 14130000000000,
        'fp-64' => 7066000000000,
      },
    },
    'Tesla M2075' => {
      'cores'              => 448,
      'compute_capability' => '2.0',
      'short_name'         => 'Tesla M2075',
      'alias'              => 'm2075',
      'microarchitecture'  => 'Maxwell',
      'performance'        => {
        'fp-16' => 0,
        'fp-32' => 1028000000000,
        'fp-64' => 513900000000,
      },
    },
    'GeForce GTX 980' => {
      'cores'              => 2048,
      'compute_capability' => '5.2',
      'short_name'         => 'GTX 980',
      'alias'              => 'gtx980',
      'microarchitecture'  => 'Fermi',
      'performance'        => {
        'fp-16' => 0,
        'fp-32' => 4981000000000,
        'fp-64' => 156000000000,
      },
    },
    'Tesla K40m' => {
      'cores'              => 2880,
      'compute_capability' => '3.5',
      'short_name'         => 'Tesla K40M',
      'alias'              => 'k40m',
      'microarchitecture'  => 'Kepler',
      'performance'        => {
        'fp-16' => 0,
        'fp-32' => 5046000000000,
        'fp-64' => 1682000000000,
      },
    },
    'Tesla K80' => {
      'cores'              => 2496,
      'compute_capability' => '3.7',
      'short_name'         => 'Tesla K80',
      'alias'              => 'k80',
      'microarchitecture'  => 'Kepler',
      'performance'        => {
        'fp-16' => 0,
        'fp-32' => 4113000000000,
        'fp-64' => 1371000000000,
      },
    },
    'H100 NVL' => {
      'cores'              => 14592,
      'compute_capability' => '9.0',
      'short_name'         => 'Tesla H100',
      'alias'              => 'h100',
      'microarchitecture'  => 'Hopper',
      'performance'        => {
        'fp-16' => 1671000000000000,
        'fp-32' => 60000000000000,
        'fp-64' => 30000000000000,
      },
    },
    'L40S' => {
      'cores'              => 18176,
      'compute_capability' => '8.9',
      'short_name'         => 'Tesla L40S',
      'alias'              => 'l40s',
      'microarchitecture'  => 'Ada Lovelace',
      'performance'        => {
        'fp-16' => 91610000000000,
        'fp-32' => 91610000000000,
        'fp-64' => 1431000000000,
      },
    },
    'Tesla M40' => {
      'cores'              => 3072,
      'compute_capability' => '5.2',
      'short_name'         => 'Tesla M40',
      'alias'              => 'm40',
      'microarchitecture'  => 'Maxwell',
      'performance'        => {
        'fp-16' => 0,
        'fp-32' => 6832000000000,
        'fp-64' => 213000000000,
      },
    },
    'Tesla T4' => {
      'cores'              => 2560,
      'compute_capability' => '7.5',
      'short_name'         => 'Tesla T4',
      'alias'              => 't4',
      'microarchitecture'  => 'Turing',
      'performance'        => {
        'fp-16' => 65130000000000,
        'fp-32' => 8141000000000,
        'fp-64' => 254000000000,
      },
    },
    'A100-PCIE-40GB' => {
      'cores'              => 6912,
      'compute_capability' => '8.0',
      'short_name'         => 'A100',
      'alias'              => 'a100-pcie-40',
      'microarchitecture'  => 'Ampere',
      'performance'        => {
        'fp-16' => 77970000000000,
        'fp-32' => 19490000000000,
        'fp-64' => 9746000000000,
      },
    },
    'A100-SXM4-40GB' => {
      'cores'              => 6912,
      'compute_capability' => '8.0',
      'short_name'         => 'A100',
      'alias'              => 'a100-sxm4-40',
      'microarchitecture'  => 'Ampere',
      'performance'        => {
        'fp-16' => 77970000000000,
        'fp-32' => 19490000000000,
        'fp-64' => 9746000000000,
      },
    },
    'A40' => {
      'cores'              => 10752,
      'compute_capability' => '8.6',
      'short_name'         => 'A40',
      'alias'              => 'a40',
      'microarchitecture'  => 'Ampere',
      'performance'        => {
        'fp-16' => 37420000000000,
        'fp-32' => 37420000000000,
        'fp-64' => 584600000000,
      },
    },
    'RTX A5000' => {
      'cores'              => 8192,
      'compute_capability' => '8.6',
      'short_name'         => 'A5000',
      'alias'              => 'a5000',
      'microarchitecture'  => 'Ampere',
      'performance'        => {
        'fp-16' => 27772650000000,
        'fp-32' => 27772650000000,
        'fp-64' => 867890000000,
      },
    },
    'Quadro P6000' => {
      'cores'              => 3840,
      'compute_capability' => '6.1',
      'short_name'         => 'Quadro P6000',
      'alias'              => 'p6000',
      'microarchitecture'  => 'Pascal',
      'performance'        => {
        'fp-16' => 197400000000,
        'fp-32' => 12630000000000,
        'fp-64' => 394800000000,
      },
    },
    'Quadro RTX 6000' => {
      'cores'              => 4608,
      'compute_capability' => '7.5',
      'short_name'         => 'Quadro RTX 6000',
      'alias'              => 'rtx6000',
      'microarchitecture'  => 'Turing',
      'performance'        => {
        'fp-16' => 32620000000000,
        'fp-32' => 16310000000000,
        'fp-64' => 510000000000,
      },     
    },
    'Quadro RTX 8000' => {
      'cores'              => 4608,
      'compute_capability' => '7.5',
      'short_name'         => 'Quadro RTX 8000',
      'alias'              => 'rtx8000',
      'microarchitecture'  => 'Turing',
      'performance'        => {
        'fp-16' => 32620000000000,
        'fp-32' => 16310000000000,
        'fp-64' => 510000000000,
      },     
    },
    'Radeon Instinct MI50 32GB' => {
      'cores'              => 5120,
      'short_name'         => 'MI50',
      'alias'              => 'mi50-32',
      'microarchitecture'  => 'Vega20',
      'performance'        => {
        'fp-16' => 26820000000000,
        'fp-32' => 13410000000000,
        'fp-64' => 510000000000,
      },  
    },
    'AGX Xavier' => {
      'cores'              => 512,
      'compute_capability' => '7.2',
      'short_name'         => 'AGX Xavier',
      'alias'              => 'agx-xavier',
      'microarchitecture'  => 'Volta',
      'performance'        => {
        'fp-16' => 2820000000000,
        'fp-32' => 1410000000000,
        'fp-64' => 705000000000,
      },  
    },
    'L40' => {
       'cores'              => 18176,
       'compute_capability' => '8.9',
       'short_name'         => 'L40',
       'alias'              => 'l40',
       'microarchitecture'  => 'Ada Lovelace',
       'performance'        => {
         'fp-16' => 9050000000000,
         'fp-32' => 9050000000000,
         'fp-64' => 141400000000,
       },
     },
  }


  def self.get_cores(model)
    if @@gpus[model]
      return @@gpus[model]['cores']
    else
      raise "Fix me: #{model} is missing"
    end
  end

  def self.get_microarchitecture(model)
    if @@gpus[model]
      return @@gpus[model]['microarchitecture']
    else
      raise "Fix me: #{model} is missing"
    end
  end

  def self.get_performance(model)
    if @@gpus[model]
      return @@gpus[model]['performance']
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

  def self.get_all_aliases
    aliases = {}
    @@gpus.each do |model, data|
      raise "Fix me: alias is missing for #{model}" unless data['alias']
      aliases[data['alias']] = model
    end

    aliases
  end

  def self.is_gpu_supported?(device)
    support = (device['vendor'] == NVIDIA) ? is_cc_supported?(device['model']) : true
    return support
  end

  def self.is_cc_supported?(model)
    compute_capability = @@gpus[model]['compute_capability']
    return (compute_capability.to_f >= MINIMAL_COMPUTE_CAPABILITY_SUPPORTED)
  end
end

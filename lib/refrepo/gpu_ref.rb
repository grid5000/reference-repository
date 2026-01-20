NVIDIA = 'Nvidia'
MINIMAL_COMPUTE_CAPABILITY_SUPPORTED = 5.2

# Sources to fill this data:
# - https://en.wikipedia.org/wiki/List_of_Nvidia_graphics_processing_units
# - https://www.techpowerup.com/gpu-specs/
class GPURef
  @@gpus = {
    'GeForce RTX 2080 Ti' => {
      'cores' => 4352,
      'compute_capability' => '7.5',
      'short_name' => 'RTX 2080 Ti',
      'alias' => 'rtx2080ti',
      'microarchitecture' => 'Turing',
      'performance' => {
        'fp-16' => 26_900_000_000_000,
        'fp-32' => 13_450_000_000_000,
        'fp-64' => 420_000_000_000
      }
    },
    'TITAN RTX' => {
      'cores' => 4608,
      'compute_capability' => '7.5',
      'short_name' => 'TITAN RTX',
      'alias' => 'titanrtx',
      'microarchitecture' => 'Turing',
      'performance' => {
        'fp-16' => 32_620_000_000_000,
        'fp-32' => 16_310_000_000_000,
        'fp-64' => 510_000_000_000
      }
    },
    'GeForce GTX 1080' => {
      'cores' => 2560,
      'compute_capability' => '6.1',
      'short_name' => 'GTX 1080',
      'alias' => 'gtx1080',
      'microarchitecture' => 'Pascal',
      'performance' => {
        'fp-16' => 138_600_000_000,
        'fp-32' => 8_872_000_000_000,
        'fp-64' => 277_200_000_000
      }
    },
    'GeForce GTX 1080 Ti' => {
      'cores' => 3584,
      'compute_capability' => '6.1',
      'short_name' => 'GTX 1080 Ti',
      'alias' => 'gtx1080ti',
      'microarchitecture' => 'Pascal',
      'performance' => {
        'fp-16' => 177_200_000_000,
        'fp-32' => 11_340_000_000_000,
        'fp-64' => 354_400_000_000
      }
    },
    'Tesla P100-PCIE-16GB' => {
      'cores' => 3584,
      'compute_capability' => '6.0',
      'short_name' => 'Tesla P100',
      'alias' => 'p100-pcie-16',
      'microarchitecture' => 'Pascal',
      'performance' => {
        'fp-16' => 19_050_000_000_000,
        'fp-32' => 9_526_000_000_000,
        'fp-64' => 4_763_000_000_000
      }
    },
    'Tesla P100-SXM2-16GB' => {
      'cores' => 3584,
      'compute_capability' => '6.0',
      'short_name' => 'Tesla P100',
      'alias' => 'p100-sxm2-16',
      'microarchitecture' => 'Pascal',
      'performance' => {
        'fp-16' => 21_220_000_000_000,
        'fp-32' => 10_610_000_000_000,
        'fp-64' => 5_304_000_000_000
      }
    },
    'Tesla V100-PCIE-16GB' => {
      'cores' => 5120,
      'compute_capability' => '7.0',
      'short_name' => 'Tesla V100',
      'alias' => 'v100-pcie-16',
      'microarchitecture' => 'Volta',
      'performance' => {
        'fp-16' => 28_260_000_000_000,
        'fp-32' => 14_130_000_000_000,
        'fp-64' => 7_066_000_000_000
      }
    },
    'Tesla V100-PCIE-32GB' => {
      'cores' => 5120,
      'compute_capability' => '7.0',
      'short_name' => 'Tesla V100',
      'alias' => 'v100-pcie-32',
      'microarchitecture' => 'Volta',
      'performance' => {
        'fp-16' => 28_260_000_000_000,
        'fp-32' => 14_130_000_000_000,
        'fp-64' => 7_066_000_000_000
      }
    },
    'Tesla V100-SXM2-32GB' => {
      'cores' => 5120,
      'compute_capability' => '7.0',
      'short_name' => 'Tesla V100',
      'alias' => 'v100-sxm2-32',
      'microarchitecture' => 'Volta',
      'performance' => {
        'fp-16' => 28_260_000_000_000,
        'fp-32' => 14_130_000_000_000,
        'fp-64' => 7_066_000_000_000
      }
    },
    'Tesla M2075' => {
      'cores' => 448,
      'compute_capability' => '2.0',
      'short_name' => 'Tesla M2075',
      'alias' => 'm2075',
      'microarchitecture' => 'Maxwell',
      'performance' => {
        'fp-16' => 0,
        'fp-32' => 1_028_000_000_000,
        'fp-64' => 513_900_000_000
      }
    },
    'GeForce GTX 980' => {
      'cores' => 2048,
      'compute_capability' => '5.2',
      'short_name' => 'GTX 980',
      'alias' => 'gtx980',
      'microarchitecture' => 'Fermi',
      'performance' => {
        'fp-16' => 0,
        'fp-32' => 4_981_000_000_000,
        'fp-64' => 156_000_000_000
      }
    },
    'TITAN X (Pascal)' => {
      'cores' => 3584,
      'compute_capability' => '6.1',
      'short_name' => 'TITAN X Pascal',
      'alias' => 'titanxpascal',
      'microarchitecture' => 'Pascal',
      'performance' => {
        'fp-16' => 171_400_000_000,
        'fp-32' => 10_974_200_000_000,
        'fp-64' => 342_900_000_000
      }
    },
    'TITAN Xp' => {
      'cores' => 3840,
      'compute_capability' => '6.1',
      'short_name' => 'TITAN Xp',
      'alias' => 'titanxp',
      'microarchitecture' => 'Pascal',
      'performance' => {
        'fp-16' => 177_600_000_000,
        'fp-32' => 12_149_700_000_000,
        'fp-64' => 355_200_000_000
      }
    },
    'GeForce GTX TITAN X' => {
      'cores' => 3072,
      'compute_capability' => '5.2',
      'short_name' => 'GTX TITAN X',
      'alias' => 'gtxtitanx',
      'microarchitecture' => 'Maxwell',
      'performance' => {
        'fp-16' => 0,
        'fp-32' => 66_050_000_000_000,
        'fp-64' => 206_500_000_000
      }
    },
    'Tesla K40m' => {
      'cores' => 2880,
      'compute_capability' => '3.5',
      'short_name' => 'Tesla K40M',
      'alias' => 'k40m',
      'microarchitecture' => 'Kepler',
      'performance' => {
        'fp-16' => 0,
        'fp-32' => 5_046_000_000_000,
        'fp-64' => 1_682_000_000_000
      }
    },
    'Tesla K80' => {
      'cores' => 2496,
      'compute_capability' => '3.7',
      'short_name' => 'Tesla K80',
      'alias' => 'k80',
      'microarchitecture' => 'Kepler',
      'performance' => {
        'fp-16' => 0,
        'fp-32' => 4_113_000_000_000,
        'fp-64' => 1_371_000_000_000
      }
    },
    'H100 NVL' => {
      'cores' => 14_592,
      'compute_capability' => '9.0',
      'short_name' => 'H100',
      'alias' => 'h100',
      'microarchitecture' => 'Hopper',
      'performance' => {
        'fp-16' => 1_671_000_000_000_000,
        'fp-32' => 60_000_000_000_000,
        'fp-64' => 30_000_000_000_000
      }
    },
    'L4' => {
      'cores' => 7424,
      'compute_capability' => '8.9',
      'short_name' => 'L4',
      'alias' => 'l4',
      'microarchitecture' => 'Ada Lovelace',
      'performance' => {
        'fp-16' => 30_290_000_000_000,
        'fp-32' => 30_290_000_000_000,
        'fp-64' => 473_300_000_000
      }
    },
    'L40S' => {
      'cores' => 18_176,
      'compute_capability' => '8.9',
      'short_name' => 'L40S',
      'alias' => 'l40s',
      'microarchitecture' => 'Ada Lovelace',
      'performance' => {
        'fp-16' => 91_610_000_000_000,
        'fp-32' => 91_610_000_000_000,
        'fp-64' => 1_431_000_000_000
      }
    },
    'Tesla M40' => {
      'cores' => 3072,
      'compute_capability' => '5.2',
      'short_name' => 'Tesla M40',
      'alias' => 'm40',
      'microarchitecture' => 'Maxwell',
      'performance' => {
        'fp-16' => 0,
        'fp-32' => 6_832_000_000_000,
        'fp-64' => 213_000_000_000
      }
    },
    'Tesla T4' => {
      'cores' => 2560,
      'compute_capability' => '7.5',
      'short_name' => 'Tesla T4',
      'alias' => 't4',
      'microarchitecture' => 'Turing',
      'performance' => {
        'fp-16' => 65_130_000_000_000,
        'fp-32' => 8_141_000_000_000,
        'fp-64' => 254_000_000_000
      }
    },
    'A100-PCIE-40GB' => {
      'cores' => 6912,
      'compute_capability' => '8.0',
      'short_name' => 'A100',
      'alias' => 'a100-pcie-40',
      'microarchitecture' => 'Ampere',
      'performance' => {
        'fp-16' => 77_970_000_000_000,
        'fp-32' => 19_490_000_000_000,
        'fp-64' => 9_746_000_000_000
      }
    },
    'A100-SXM4-40GB' => {
      'cores' => 6912,
      'compute_capability' => '8.0',
      'short_name' => 'A100',
      'alias' => 'a100-sxm4-40',
      'microarchitecture' => 'Ampere',
      'performance' => {
        'fp-16' => 77_970_000_000_000,
        'fp-32' => 19_490_000_000_000,
        'fp-64' => 9_746_000_000_000
      }
    },
    'A100 80GB PCIe' => {
      'cores' => 6912,
      'compute_capability' => '8.0',
      'short_name' => 'A100',
      'alias' => 'a100-pcie-80',
      'microarchitecture' => 'Ampere',
      'performance' => {
        'fp-16' => 77_970_000_000_000,
        'fp-32' => 19_490_000_000_000,
        'fp-64' => 9_746_000_000_000
      }
    },
    'A40' => {
      'cores' => 10_752,
      'compute_capability' => '8.6',
      'short_name' => 'A40',
      'alias' => 'a40',
      'microarchitecture' => 'Ampere',
      'performance' => {
        'fp-16' => 37_420_000_000_000,
        'fp-32' => 37_420_000_000_000,
        'fp-64' => 584_600_000_000
      }
    },
    'RTX A5000' => {
      'cores' => 8192,
      'compute_capability' => '8.6',
      'short_name' => 'A5000',
      'alias' => 'a5000',
      'microarchitecture' => 'Ampere',
      'performance' => {
        'fp-16' => 27_772_650_000_000,
        'fp-32' => 27_772_650_000_000,
        'fp-64' => 867_890_000_000
      }
    },
    'RTX A6000' => {
      'cores' => 10_752,
      'compute_capability' => '8.6',
      'short_name' => 'A6000',
      'alias' => 'a6000',
      'microarchitecture' => 'Ampere',
      'performance' => {
        'fp-16' => 38_710_000_000_000,
        'fp-32' => 38_710_000_000_000,
        'fp-64' => 604_800_000_000
      }
    },

    'Quadro P6000' => {
      'cores' => 3840,
      'compute_capability' => '6.1',
      'short_name' => 'Quadro P6000',
      'alias' => 'p6000',
      'microarchitecture' => 'Pascal',
      'performance' => {
        'fp-16' => 197_400_000_000,
        'fp-32' => 12_630_000_000_000,
        'fp-64' => 394_800_000_000
      }
    },
    'Quadro RTX 6000' => {
      'cores' => 4608,
      'compute_capability' => '7.5',
      'short_name' => 'Quadro RTX 6000',
      'alias' => 'rtx6000',
      'microarchitecture' => 'Turing',
      'performance' => {
        'fp-16' => 32_620_000_000_000,
        'fp-32' => 16_310_000_000_000,
        'fp-64' => 510_000_000_000
      }
    },
    'RTX 6000 Ada Generation' => {
      'cores' => 18_176,
      'compute_capability' => '8.9',
      'short_name' => 'RTX 6000 Ada',
      'alias' => 'rtx6000Ada',
      'microarchitecture' => 'Ada Lovelace',
      'performance' => {
        'fp-16' => 91_060_000_000_000,
        'fp-32' => 91_060_000_000_000,
        'fp-64' => 142_280_000_000
      }
    },
    'RTX PRO 6000 Blackwell Server Edition' => {
      'cores' => 24_064,
      'compute_capability' => '11.6',
      'short_name' => 'RTX PRO 6000',
      'alias' => 'rtxpro6000',
      'microarchitecture' => 'Blackwell',
      'performance' => {
        'fp-16' => 126_000_000_000_000,
        'fp-32' => 126_000_000_000_000,
        'fp-64' => 1_968_000_000_000
      }
    },
    'Quadro RTX 8000' => {
      'cores' => 4608,
      'compute_capability' => '7.5',
      'short_name' => 'Quadro RTX 8000',
      'alias' => 'rtx8000',
      'microarchitecture' => 'Turing',
      'performance' => {
        'fp-16' => 32_620_000_000_000,
        'fp-32' => 16_310_000_000_000,
        'fp-64' => 510_000_000_000
      }
    },
    'Radeon Instinct MI50 32GB' => {
      'cores' => 5120,
      'short_name' => 'MI50',
      'alias' => 'mi50-32',
      'microarchitecture' => 'Vega20',
      'performance' => {
        'fp-16' => 26_820_000_000_000,
        'fp-32' => 13_410_000_000_000,
        'fp-64' => 510_000_000_000
      }
    },
    'AMD Instinct MI300X' => {
      'cores' => 19_456,
      'short_name' => 'MI300X',
      'alias' => 'mi300x',
      'microarchitecture' => 'Aqua Vanjaram',
      'performance' => {
        'fp-16' => 653_700_000_000_000,
        'fp-32' => 81_720_000_000_000,
        'fp-64' => 81_720_000_000_000
      }
    },
    'Instinct MI210' => {
      'cores' => 6656,
      'short_name' => 'MI210',
      'alias' => 'mi210',
      'microarchitecture' => 'Aldebaran',
      'performance' => {
        'fp-16' => 181_000_000_000_000,
        'fp-32' => 22_600_000_000_000,
        'fp-64' => 22_600_000_000_000
      }
    },
    'AGX Xavier' => {
      'cores' => 512,
      'compute_capability' => '7.2',
      'short_name' => 'AGX Xavier',
      'alias' => 'agx-xavier',
      'microarchitecture' => 'Volta',
      'performance' => {
        'fp-16' => 2_820_000_000_000,
        'fp-32' => 1_410_000_000_000,
        'fp-64' => 705_000_000_000
      }
    },
    'L40' => {
      'cores' => 18_176,
      'compute_capability' => '8.9',
      'short_name' => 'L40',
      'alias' => 'l40',
      'microarchitecture' => 'Ada Lovelace',
      'performance' => {
        'fp-16' => 90_520_000_000_000,
        'fp-32' => 90_520_000_000_000,
        'fp-64' => 1_414_300_000_000
      }
    },
    'GH200' => {
      'cores' => 18_176,
      'compute_capability' => '9.0',
      'short_name' => 'H200',
      'alias' => 'H200',
      'microarchitecture' => 'Hopper',
      'performance' => {
        # Performance informations comes from:
        #   https://www.nvidia.com/en-us/data-center/h200/
        'fp-16' => 19_790_000_000_000, # FP-16 Tensor Core value, no flops available for FP-16.
        'fp-32' => 670_000_000_000_000,
        'fp-64' => 340_000_000_000_000
      }
    }
  }

  def self.get_cores(model)
    return @@gpus[model]['cores'] if @@gpus[model]

    raise "Fix me: #{model} is missing"
  end

  def self.get_microarchitecture(model)
    return @@gpus[model]['microarchitecture'] if @@gpus[model]

    raise "Fix me: #{model} is missing"
  end

  def self.get_performance(model)
    return @@gpus[model]['performance'] if @@gpus[model]

    raise "Fix me: #{model} is missing"
  end

  def self.model2shortname(model)
    return @@gpus[model]['short_name'] if @@gpus[model]

    raise "Missing short name for model: #{model}"
  end

  def self.get_compute_capability(model)
    return @@gpus[model]['compute_capability'] || nil if @@gpus[model]

    raise "Fix me: #{model} is missing"
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
    device['vendor'] == NVIDIA ? is_cc_supported?(device['model']) : true
  end

  def self.is_cc_supported?(model)
    compute_capability = @@gpus[model]['compute_capability']
    compute_capability.to_f >= MINIMAL_COMPUTE_CAPABILITY_SUPPORTED
  end
end

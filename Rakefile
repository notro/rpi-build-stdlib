require 'stdlib/base'
require 'stdlib/rpi-linux'
require 'stdlib/linux'

release :rpi_linux_master => [:issue106, :rpi_tools, :rpi_firmware, :rpi_linux]

release :rpi_linux_next => [:issue106, :rpi_tools, :rpi_firmware, :rpi_linux] do
  something
end

release :linux => [:issue106, :rpi_tools, :rpi_firmware, :uboot_bcm2835, :kernel_org] do
  raise "missing KERNEL_ORG_VERSION environment variable (e.g. 3.14.3)" unless VAR['KERNEL_ORG_VERSION']
end

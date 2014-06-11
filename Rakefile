require 'stdlib/base'
require 'stdlib/rpi-linux'
require 'stdlib/uboot'
require 'stdlib/rpi-linux-dt'
require 'stdlib/linux'

# get linux sha from raspberrypi/firmware master branch
release :rpi_linux => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :vboot, :raspberrypi_linux]

# get linux sha from raspberrypi/firmware next branch
release :rpi_linux_latest => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :vboot, :raspberrypi_linux] do
  VAR['RPI_FIRMWARE_BRANCH'] = 'latest'
end

# get linux sha from raspberrypi/firmware master branch
release :rpi_linux_dt => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :uboot_bcm2708, :raspberrypi_linux_dt]


release :linux => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :uboot_bcm2835, :kernel_org] do
  raise "missing KERNEL_ORG_VERSION environment variable (e.g. 3.14.3)" unless VAR['KERNEL_ORG_VERSION']
  VAR.store 'KERNEL_ORG_VERSION'
end

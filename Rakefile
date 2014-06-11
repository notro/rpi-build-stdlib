require 'stdlib/base'
require 'stdlib/rpi-linux'
require 'stdlib/uboot'
require 'stdlib/rpi-linux-dt'
require 'stdlib/linux'

# get linux sha from raspberrypi/firmware master branch
release :rpi_linux => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :vboot, :raspberrypi_linux]

release :rpi_linux_latest => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :vboot, :raspberrypi_linux] do
  VAR['RPI_LINUX_BRANCH'] ||= raspberrypi_linux_latest
  info "RPI_LINUX_BRANCH = #{ENV['RPI_LINUX_BRANCH']}"
end

# get linux sha from raspberrypi/firmware master branch
release :rpi_linux_dt => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :uboot_bcm2708, :raspberrypi_linux_dt]


release :linux => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :uboot_bcm2835, :kernelorg_linux] do
  VAR['KERNEL_ORG_VERSION'] ||= kernelorg_linux_latest
  VAR.store 'KERNEL_ORG_VERSION'
  info "KERNEL_ORG_VERSION = #{VAR['KERNEL_ORG_VERSION']}"
end

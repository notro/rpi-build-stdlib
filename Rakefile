require 'stdlib/base'
require 'stdlib/rpi-linux'
require 'stdlib/uboot'
require 'stdlib/linux'

# get linux ref from raspberrypi/firmware master branch
release :rpi_linux => :rpi_linux_common

release :rpi_linux_latest => :rpi_linux_common do
  VAR['RASPBERRYPI_LINUX_BRANCH'] ||= raspberrypi_linux_latest
  info "RASPBERRYPI_LINUX_BRANCH = #{ENV['RASPBERRYPI_LINUX_BRANCH']}"
end

release :rpi_linux_dt => [:rpi_linux_common, :vcboot_dt] do
  VAR['RASPBERRYPI_LINUX_BRANCH'] ||= raspberrypi_linux_latest
  VAR.store 'RASPBERRYPI_LINUX_BRANCH'
  info "RASPBERRYPI_LINUX_BRANCH = #{VAR['RASPBERRYPI_LINUX_BRANCH']}"
  config ['BCM2708_DT', 'DYNAMIC_DEBUG', 'PROC_DEVICETREE'], :enable
  config ['SPI_BCM2835', 'I2C_BCM2835'], :module
end

release :linux => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :uboot_bcm2835, :kernelorg_linux] do
  VAR['KERNEL_ORG_VERSION'] ||= kernelorg_linux_latest
  VAR.store 'KERNEL_ORG_VERSION'
  info "KERNEL_ORG_VERSION = #{VAR['KERNEL_ORG_VERSION']}"
end

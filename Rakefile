require 'stdlib/base'
require 'stdlib/rpi-linux'
require 'stdlib/uboot'
require 'stdlib/rpi-linux-dt'
require 'stdlib/linux'

package :rpi_linux_common => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :vboot, :raspberrypi_linux]

# get linux ref from raspberrypi/firmware master branch
release :rpi_linux => :rpi_linux_common

release :rpi_linux_latest => :rpi_linux_common do
  VAR['RASPBERRYPI_LINUX_BRANCH'] ||= raspberrypi_linux_latest
  info "RASPBERRYPI_LINUX_BRANCH = #{ENV['RASPBERRYPI_LINUX_BRANCH']}"
end

# get linux ref from raspberrypi/firmware master branch
release :rpi_linux_dt => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :uboot_bcm2708, :raspberrypi_linux_dt]


release :linux => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :uboot_bcm2835, :kernelorg_linux] do
  VAR['KERNEL_ORG_VERSION'] ||= kernelorg_linux_latest
  VAR.store 'KERNEL_ORG_VERSION'
  info "KERNEL_ORG_VERSION = #{VAR['KERNEL_ORG_VERSION']}"
end

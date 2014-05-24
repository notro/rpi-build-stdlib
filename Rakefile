require 'stdlib/base'
require 'stdlib/rpi-linux'

release :rpi_linux_master => [:issue106, :rpi_tools, :rpi_firmware, :rpi_linux] do
  ENV['LINUX_DEFCONFIG'] = 'bcmrpi_defconfig'
end



require 'stdlib/linux'

release :linux => [:issue106, :rpi_tools, :rpi_firmware, :uboot, :linux_org] do
  raise "missing LINUX_ORG_VERSION environment variable (e.g. 3.14.3)" unless ENV['LINUX_ORG_VERSION']
  Readme.desc """
Linux kernel #{ENV['LINUX_ORG_VERSION']} for the Raspberry Pi
"""
  ENV['LINUX_DEFCONFIG'] = 'bcm2835_defconfig'
  config 'DYNAMIC_DEBUG', :enable

end

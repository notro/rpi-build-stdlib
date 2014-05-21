require 'http'
require 'stdlib/base'

package :rpi_linux do
  # if branch is set, use it
  ENV['RPI_LINUX_SHA'] ||= github_get_head('raspberrypi/firmware', ENV['RPI_LINUX_BRANCH']) if ENV['RPI_LINUX_BRANCH']
  # else use the commit that was used to build the firmware
  ENV['RPI_LINUX_SHA'] ||= Http.get("https://raw.githubusercontent.com/raspberrypi/firmware/#{ENV['RPI_FIRMWARE_SHA']}/extra/git_hash").to_s.strip

  github_tarball "raspberrypi/linux", 'linux', ENV['RPI_LINUX_SHA']

  config 'LOCALVERSION', :str, "+"

  task :install do
    dst = workdir 'out'
    ksrc = workdir 'linux'
    msrc = workdir 'modules'

		cp_r(ksrc + "/arch/arm/boot/Image", dst + "/kernel.img")
		mkdir_p(dst + "/modules")
		sh "cp -r #{msrc}/lib/modules/*+ #{dst}/modules/"
		sh "cp -r #{msrc}/lib/firmware #{dst}/"
		cp_r(ksrc + "/Module.symvers", dst)
    File.open("#{dst}/git_hash", 'w') { |file| file.write(ENV['RPI_LINUX_SHA']) }
		mkdir_p(dst + "/extra")
		cp_r(ksrc + "/System.map", dst + "/extra/")
		cp_r(ksrc + "/.config", dst + "/extra/")
  end
end

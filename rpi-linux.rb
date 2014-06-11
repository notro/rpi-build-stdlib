
# VideoCore bootloader
package :vboot do
  target :build do
		cp_r workdir('linux/arch/arm/boot/Image'), workdir('out/kernel.img')
  end
end

package :raspberrypi_linux do
  # if branch is set, use it
  VAR['RPI_LINUX_SHA'] ||= github_get_head('raspberrypi/linux', VAR['RPI_LINUX_BRANCH']) if VAR['RPI_LINUX_BRANCH']
  # else use the commit that was used to build the firmware
  VAR['RPI_LINUX_SHA'] ||= http_get("https://raw.githubusercontent.com/raspberrypi/firmware/#{VAR['RPI_FIRMWARE_SHA']}/extra/git_hash").to_s.strip

  # override default env vars: RPI_LINUX_BRANCH and RPI_LINUX_SHA
  github_tarball "raspberrypi/linux", 'linux', 'RPI_LINUX'

  ENV['LINUX_DEFCONFIG'] ||= 'bcmrpi_defconfig'

  # When building directly from a git repo, KERNELRELEASE gets a '+' appended
  # When we build from a tarball, the Makefile can't see we're not vanilla, so we have to set it manually.
  # Options:
  # * Use a localversion file: if we use diffprep it's turned into a git repo and we end up with ++
  # * Use LOCALVERSION env var: This will be lost if doing work outside of rpi-build
  # * Use a .scmversion file: This will be used regardless of git or no git
  #
  # In short from Makefile:
  # KERNELRELEASE = @echo "$(KERNELVERSION)$$($(CONFIG_SHELL) $(srctree)/scripts/setlocalversion $(srctree))"
  #
  target :unpack do
    File.write workdir('linux/.scmversion'), '+'
  end

  target :build do
    dst = workdir 'out'
    ksrc = workdir 'linux'
    msrc = workdir 'modules'

		mkdir_p(dst + "/modules")
    sh "cp -r #{msrc}/lib/modules/* #{dst}/modules/" unless FileList["#{msrc}/lib/modules/*"].empty?
    sh "cp -r #{msrc}/lib/firmware #{dst}/" unless FileList["#{msrc}/lib/firmware/*"].empty?
		cp_r(ksrc + "/Module.symvers", dst)
    File.open("#{dst}/git_hash", 'w') { |file| file.write(VAR['RPI_LINUX_SHA']) }
		mkdir_p(dst + "/extra")
		cp_r(ksrc + "/System.map", dst + "/extra/")
		cp_r(ksrc + "/.config", dst + "/extra/")
  end
end

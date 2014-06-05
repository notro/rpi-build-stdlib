
package :rpi_linux do
  # if branch is set, use it
  VAR['RPI_LINUX_SHA'] ||= github_get_head('raspberrypi/linux', VAR['RPI_LINUX_BRANCH']) if VAR['RPI_LINUX_BRANCH']
  # else use the commit that was used to build the firmware
  VAR['RPI_LINUX_SHA'] ||= http_get("https://raw.githubusercontent.com/raspberrypi/firmware/#{VAR['RPI_FIRMWARE_SHA']}/extra/git_hash").to_s.strip

  # override default env vars: RPI_LINUX_BRANCH and RPI_LINUX_SHA
  github_tarball "raspberrypi/linux", 'linux', 'RPI_LINUX'

  ENV['LINUX_DEFCONFIG'] ||= 'bcmrpi_defconfig'

  # When building directly from the git repo, KERNELRELEASE gets a '+' appended
  # When we build from a tarball, the Makefile can't see we're not vanilla, so we set it manually.
  # In short from Makefile:
  # KERNELRELEASE = @echo "$(KERNELVERSION)$$($(CONFIG_SHELL) $(srctree)/scripts/setlocalversion $(srctree))"
  target :patch do
    fn = workdir 'linux/localversion+'
    info "Create #{fn}"
    File.open(fn, 'w') { |file| file.write '+' }
  end

  target :build do
    dst = workdir 'out'
    ksrc = workdir 'linux'
    msrc = workdir 'modules'

		cp_r(ksrc + "/arch/arm/boot/Image", dst + "/kernel.img")
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

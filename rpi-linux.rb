require 'stdlib/base'

package :rpi_linux_common => [:issue106, :raspberrypi_tools, :raspberrypi_firmware, :vcboot, :raspberrypi_linux]

# VideoCore bootloader
package :vcboot do
  target :build do
		cp_r workdir('linux/arch/arm/boot/Image'), workdir('out/kernel.img')
  end
end

def raspberrypi_linux_latest
  cmd = "git ls-remote -h https://github.com/raspberrypi/linux"
  s = `#{cmd}`
  unless $?.exitstatus == 0
    puts cmd
    puts s
    raise "Could not get latest branch from raspberrypi/linux (status #{$?.exitstatus})"
  end
  branch = nil
  last = 0
  s.scan(/^[0-9a-f]+\s+refs\/heads\/rpi\-(\d)\.(\d+)\.y(.*)$/).each do |m|
    next unless m[2].empty?
    weight = m[0].to_i * 1000 + m[1].to_i
    if weight > last
      last = weight
      branch = "rpi-#{m[0]}.#{m[1]}.y"
    end
  end
  unless branch
    puts s
    raise "Could not get latest branch from raspberrypi/linux"
  end
  branch
 end

package :raspberrypi_linux do
  # if branch is set, use it
  VAR['RASPBERRYPI_LINUX_REF'] ||=
    github_get_head('raspberrypi/linux', VAR['RASPBERRYPI_LINUX_BRANCH']) if VAR['RASPBERRYPI_LINUX_BRANCH']
  # else use the commit that was used to build the firmware
  VAR['RASPBERRYPI_LINUX_REF'] ||=
    http_get("https://raw.githubusercontent.com/raspberrypi/firmware/"\
             "#{VAR['RASPBERRYPI_FIRMWARE_REF']}/extra/git_hash").to_s.strip

  github_tarball "raspberrypi/linux", 'linux', 'RASPBERRYPI_LINUX'

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
    File.open("#{dst}/git_hash", 'w') { |file| file.write(VAR['RASPBERRYPI_LINUX_REF']) }
		mkdir_p(dst + "/extra")
		cp_r(ksrc + "/System.map", dst + "/extra/")
		cp_r(ksrc + "/.config", dst + "/extra/")
  end
end

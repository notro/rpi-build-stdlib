# not needed when building on the Raspberry Pi
unless rpi?
  package :raspberrypi_tools do
    if VAR['CROSS_COMPILE'] && File.exists?(File.dirname VAR['CROSS_COMPILE'])
      puts "raspberrypi_tools: CROSS_COMPILE=#{VAR['CROSS_COMPILE']}"
    else
      github_tarball 'raspberrypi/tools', 'tools', 'RASPBERRYPI_TOOLS'
    end
  end
else
  package :raspberrypi_tools
end

package :raspberrypi_firmware do |t|
  github_tarball 'raspberrypi/firmware', 'firmware', 'RASPBERRYPI_FIRMWARE'

  target :build do
    src = workdir 'firmware'
    dst = workdir 'out'

    fl = Rake::FileList["#{src}/boot/*.bin", "#{src}/boot/*.dat", "#{src}/boot/*.elf",
                        "#{src}/boot/COPYING*", "#{src}/boot/LICENCE*"]
    cp fl, "#{dst}/"

    mkdir_p(dst + "/vc/sdk/opt/vc")
		cp_r(src + "/opt/vc/include/", dst + "/vc/sdk/opt/vc/")
		cp_r(src + "/opt/vc/src/",  dst + "/vc/sdk/opt/vc/")
		# delete due to size 30MB
		rm_rf(dst + "/vc/sdk/opt/vc/src/hello_pi/hello_video/test.h264")

		mkdir_p(dst + "/vc/softfp/opt/vc")
		cp_r(src + "/opt/vc/LICENCE", dst + "/vc/softfp/opt/vc")
		cp_r(src + "/opt/vc/bin/", dst + "/vc/softfp/opt/vc")
		cp_r(src + "/opt/vc/lib/", dst + "/vc/softfp/opt/vc")
		cp_r(src + "/opt/vc/sbin/", dst + "/vc/softfp/opt/vc")

		mkdir_p(dst + "/vc/hardfp/opt/vc")
		cp_r(src + "/hardfp/opt/vc/LICENCE", dst + "/vc/hardfp/opt/vc")
		cp_r(src + "/hardfp/opt/vc/bin/", dst + "/vc/hardfp/opt/vc")
		cp_r(src + "/hardfp/opt/vc/lib/", dst + "/vc/hardfp/opt/vc")
		cp_r(src + "/hardfp/opt/vc/sbin/", dst + "/vc/hardfp/opt/vc")
  end
end

def rpi_kernel7?
  `grep 'CONFIG_LOCALVERSION="-v7"' #{workdir('linux/.config')}`
  if $?.exitstatus == 0
    true
  else
    false
  end
end

# VideoCore bootloader
package :vcboot do
  target :build do
    VAR['KERNEL_IMG'] ||= 'kernel.img'
    VAR['KERNEL7_IMG'] ||= 'kernel7.img'
    if FileList[workdir('linux/arch/arm/boot/dts/*.dtb')].empty?
      cp workdir('linux/arch/arm/boot/zImage'), workdir("out/#{VAR['KERNEL_IMG']}")
    else
      VAR['MKKNLIMG'] ||= File.realpath '../../../mkimage/mkknlimg', File.dirname(cross_compile(nil))
      if rpi_kernel7?
        imgname = VAR['KERNEL7_IMG']
      else
        imgname = VAR['KERNEL_IMG']
      end
      sh "#{VAR['MKKNLIMG']} --dtok #{workdir('linux/arch/arm/boot/zImage')} #{workdir('out/')}#{imgname}"
      sh "cp #{workdir('linux/arch/arm/boot/dts/*.dtb')} #{workdir('out')}"
      mkdir_p workdir('out/overlays')
      sh "mv #{workdir('out/*overlay.dtb')} #{workdir('out/overlays/')}" unless FileList[workdir('out/*overlay.dtb')].empty?
    end
  end
end

package :dtc do
  begin
    res = `dtc -v`
  rescue => e
    info "
ERROR: is dtc (Device Tree compiler) installed?

Plugin (-@) support is required and might not be available in the Debian package.

This will give a working version:

wget -c https://raw.githubusercontent.com/RobertCNelson/tools/master/pkgs/dtc.sh
chmod +x dtc.sh
./dtc.sh

"
    raise
  end
  res = `dtc -@ -h 2>&1`
  if $?.exitstatus != 0
    if res.include? 'unknown option'
      raise "ERROR: dtc doesn't support -@ (#{`dtc -v 2>&1`.strip})"
    end
    raise "ERROR: failed to run dtc (#{$?.exitstatus})"
  end
end

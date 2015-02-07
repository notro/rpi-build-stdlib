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

# https://github.com/Hexxeh/rpi-update/issues/106
package :issue106 do
  target :kbuild do
		pre_install <<END
echo "     Work around rpi-update issue #106"
find "${FW_REPOLOCAL}/modules" -mindepth 1 -maxdepth 1 -type d | while read DIR; do
	BASEDIR=$(basename "${DIR}")
	echo "     rm -rf ${FW_MODPATH}/${BASEDIR}/kernel"
	rm -rf "${FW_MODPATH}/${BASEDIR}/kernel"
done

END
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
    if FileList[workdir('linux/arch/arm/boot/dts/*.dtb')].empty?
      cp workdir('linux/arch/arm/boot/zImage'), workdir('out/kernel.img')
    else
      VAR['MKKNLIMG'] ||= File.realpath '../../../mkimage/mkknlimg', File.dirname(cross_compile(nil))
      if rpi_kernel7?
        imgname = 'kernel7.img'
      else
        imgname = 'kernel.img'
      end
      sh "#{VAR['MKKNLIMG']} #{workdir('linux/arch/arm/boot/zImage')} #{workdir('out/')}#{imgname}"
      sh "cp #{workdir('linux/arch/arm/boot/dts/*.dtb')} #{workdir('out')}"
      mkdir_p workdir('out/overlays')
      sh "mv #{workdir('out/*overlay.dtb')} #{workdir('out/overlays/')}"
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

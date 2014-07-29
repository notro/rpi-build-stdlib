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

		# Using FileList gives a hard to read output with all the files listed on the command line
    sh "cp -r #{src}/boot/* #{dst}/"

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

# VideoCore bootloader
package :vcboot do
  target :build do
    cp workdir('linux/arch/arm/boot/zImage'), workdir('out/kernel.img')
  end
end

package :vcboot_dt => :vcboot do
  target :build do
    dst = workdir 'out'
    ksrc = workdir 'linux'
    sh "cp #{workdir('linux/arch/arm/boot/dts/*.dtb')} #{workdir('out')}"
  end

  target :kbuild do

    post_install <<END

src=${BOOT_PATH}/config.txt
dst=${src}.$(date +%Y-%m-%d--%H-%M-%S)

if grep -q "^device_tree=bcm2708-rpi-b.dtb" ${src}; then
  echo "     ${src}: DT is already enabled"
else
  echo "     Backup ${src} -> ${dst}"
  cp -a ${src} ${dst}
  echo "     Adding Device Tree options to ${src}"
  cat <<EOM >> ${src}

# Boot a Device Tree enabled kernel
device_tree=bcm2708-rpi-b.dtb
device_tree_address=0x100
kernel_address=0x8000
disable_commandline_tags=2
EOM
  echo
  echo "     Remember to restore/edit ${src} when installing a non-DT kernel"
  echo
fi

END
  end
end

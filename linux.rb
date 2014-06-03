
package :uboot do
  gitweb_tarball 'http://git.denx.de/?p=u-boot/u-boot-arm.git', 'u-boot', 'UBOOT'

  # regarding USB controller power: https://plus.google.com/+StephenWarren/posts/gWkwrfNfYVm
  scr = <<END
if test -n "$bootargs"; then
        echo Using bootargs from uEnv.txt
else
        echo Using default bootargs
        setenv bootargs 'earlyprintk loglevel=8 console=ttyAMA0 verbose rootwait root=/dev/mmcblk0p2 rw'
fi
echo Turn on USB controller power...
setenv prop-2-2 'mw.l 0x00001000 0x00000020 ; mw.l 0x00001004 0x00000000 ; mw.l 0x00001008 \$tag ; mw.l 0x0000100c 0x00000008 ; mw.l 0x00001010 0x00000008 ; mw.l 0x00001014 \$p1 ; mw.l 0x00001018 \$p2 ; mw.l 0x0000101c 0x00000000 ; md.l 0x1000 8'
setenv send-rec 'mw 0x2000b8a0 0x00001008 ; md 0x2000b880 1 ; md.l 0x00001000 8'
setenv tag 0x28001 ; setenv p1 3 ; setenv p2 3; run prop-2-2 ; run send-rec
fatload ${devtype} ${devnum}:1 ${kernel_addr_r} /zImage
fatload ${devtype} ${devnum}:1 ${fdt_addr_r} /${fdtfile}
bootz ${kernel_addr_r} - ${fdt_addr_r}
END

  uenv = <<EOM
# UEnv.txt is imported during the preboot variable execution.

# Override the default bootargs adding some debug output:
#bootargs=earlyprintk loglevel=8 console=ttyAMA0 verbose rootwait root=/dev/mmcblk0p2 rw debug dyndbg=\\\"module pinctrl_bcm2835 +p; file drivers/gpio/gpiolib.c +p; file drivers/of/platform.c +p; file kernel/irq/irqdomain.c +p; file kernel/irq/manage.c +p; file kernel/resource.c +p;\\\"

# Override bootcmd
#bootcmd=echo Overriding bootcmd...; for target in ${boot_targets}; do run bootcmd_${target}; done
EOM

  target :kbuild do
    sh "cd #{workdir 'u-boot'} && #{cross_compile} ./MAKEALL --continue rpi_b"

    scr_fn = workdir 'boot.scr'
    File.open(scr_fn, 'w') { |file| file.write scr }
    mkimage = workdir 'u-boot/tools/mkimage'
    sh "#{mkimage} -T script -d #{scr_fn} #{workdir 'boot.scr.uimg'}"

    File.open(workdir('uEnv.txt'), 'w') { |file| file.write uenv }

		post_install <<EOM
cp "${FW_REPOLOCAL}/"*.uimg "${FW_PATH}/"
cp "${FW_REPOLOCAL}/"uEnv.txt "${FW_PATH}/"

EOM

  end

  target :build do
    dst = workdir 'out'
    cp workdir('boot.scr.uimg'), dst
    cp workdir('uEnv.txt'), dst
    cp workdir('u-boot/u-boot.bin'), "#{dst}/kernel.img"
  end

end

package :linux_org do
  raise "missing environment variable LINUX_ORG_VERSION" unless VAR['LINUX_ORG_VERSION']
  fn = "linux-#{VAR['LINUX_ORG_VERSION']}.tar.xz"
  dl = download "https://www.kernel.org/pub/linux/kernel/v3.x/#{fn}", fn, "linux-#{VAR['LINUX_ORG_VERSION']}.tar.xz"
  un = unpack fn, 'linux'
  un.enhance [dl.name]

  ENV['LINUX_DEFCONFIG'] ||= 'bcm2835_defconfig'
  config ['CONFIG_IKCONFIG', 'CONFIG_IKCONFIG_PROC'], :enable
  config 'PROC_DEVICETREE', :enable

  target :kbuild do
    post_install <<EOM
cp "${FW_REPOLOCAL}/zImage" "${FW_PATH}/"

EOM
	end

  target :build do
    dst = workdir 'out'
    ksrc = workdir 'linux'
    msrc = workdir 'modules'

    cp(ksrc + "/arch/arm/boot/zImage", dst)
    sh "cp #{ksrc}/arch/arm/boot/dts/*.dtb #{dst}"
    mkdir_p(dst + "/modules")
    sh "cp -r #{msrc}/lib/modules/* #{dst}/modules/" unless FileList["#{msrc}/lib/modules/*"].empty?
    sh "cp -r #{msrc}/lib/firmware #{dst}/" unless FileList["#{msrc}/lib/firmware/*"].empty?
    cp(ksrc + "/Module.symvers", dst)
    mkdir_p(dst + "/extra")
    cp(ksrc + "/System.map", dst + "/extra/")
    cp(ksrc + "/.config", dst + "/extra/")
  end

end


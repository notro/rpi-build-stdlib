
package :uboot_arm do
  gitweb_tarball 'http://git.denx.de/?p=u-boot/u-boot-arm.git', 'u-boot', 'UBOOT'

  target :kbuild do
    sh "cd #{workdir 'u-boot'} && #{cross_compile} ./MAKEALL --continue rpi_b"
  end

  target :build do
    dst = workdir 'out'
    cp workdir('u-boot/u-boot.bin'), "#{dst}/kernel.img"
  end
end

package :uboot_bcm2835 => :uboot_arm do
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
  end
end

# VideoCore bootloader reads cmdline.txt, add's some parameters of it's own, and passes it via ATAGS.
# U-Boot reads ATAG_CMDLINE and sets the 'bootargs' environment variable
# U-Boot copies the bootargs variable to Device Tree chosen/bootargs
package :uboot_bcm2708 => :uboot_arm do
  target :patch do
    Readme.patch "* U-Boot: Copy ATAG_CMDLINE to bootargs environment variable\n"
    insert_before workdir('u-boot/include/configs/rpi_b.h'), '#define CONFIG_SYS_DCACHE_OFF', "#define CONFIG_MISC_INIT_R\n"
    fn = workdir('u-boot/board/raspberrypi/rpi_b/rpi_b.c')
    insert_after fn, "#include <asm/global_data.h>\n", "#include <asm/setup.h>\n"
    s = <<'EOM'

int misc_init_r(void)
{
	struct tag *t = (struct tag *)gd->bd->bi_boot_params;

	/* First tag must be ATAG_CORE */
	if (t->hdr.tag != ATAG_CORE) {
    printf("No ATAGS found");
		return 0;
  }

	/* Last tag must be ATAG_NONE */
	while (t->hdr.tag != ATAG_NONE) {
		switch (t->hdr.tag) {
    case ATAG_CMDLINE:
      if (setenv("bootargs", t->u.cmdline.cmdline) != 0)
        printf("WARNING: Could not set 'bootargs' variable from ATAGS\n");
      break;
		}
		t = tag_next(t);
	}
  return 0;
}

EOM
    File.open(fn, 'a') { |f| f.write s }
  end

  uenv = <<'EOM'
# UEnv.txt is imported during the preboot variable execution.

fdtfile=bcm2708-rpi-b.dtb
scan_boot=fatload ${devtype} ${devnum}:1 ${kernel_addr_r} /zImage; fatload ${devtype} ${devnum}:1 ${fdt_addr_r} /${fdtfile}; bootz ${kernel_addr_r} - ${fdt_addr_r}

EOM

  target :kbuild do
    File.write workdir('uEnv.txt'), uenv

		post_install <<EOM
cp "${FW_REPOLOCAL}/"uEnv.txt "${FW_PATH}/"

EOM
  end

  target :build do
    dst = workdir 'out'
    cp workdir('uEnv.txt'), dst
  end
end

require 'stdlib/base'
require 'stdlib/uboot'
require 'stdlib/rpi-linux'


package :raspberrypi_linux_dt => :raspberrypi_linux do

  # pinctrl driver
  # Verbatim copy of pinctrl-bcm2835.c except for the probe funtion.
  # Connects to the existing gpio_chip registered in bcm2708_gpio.
  #   drivers/pinctrl/pinctrl-bcm2708.c
  target :patch do
    Readme.patch "* Add drivers/pinctrl/pinctrl-bcm2708.c\n"
    insert_before workdir('linux/drivers/pinctrl/Kconfig'), 'config PINCTRL_BCM2835', <<EOM
config PINCTRL_BCM2708
	bool
	select PINMUX
	select PINCONF

EOM
    insert_before workdir('linux/drivers/pinctrl/Makefile'), 'obj-$(CONFIG_PINCTRL_BCM2835)	+= pinctrl-bcm2835.o', "obj-$(CONFIG_PINCTRL_BCM2708)   += pinctrl-bcm2708.o\n"

    # Create drivers/pinctrl/pinctrl-bcm2708.c
    # extract probe function
    re = %r{
      static\sint\sbcm2835_pinctrl_probe\(struct\splatform_device\s\*pdev\)\s
      (?<re>
        \{
          (?:
            (?> [^{}]+ )
            |
            \g<re>
          )*
        \}
      )
    }x
    s = File.read workdir 'linux/drivers/pinctrl/pinctrl-bcm2835.c'
    s.slice! re
    # switch identity
    s.gsub! '2835', '2708'
    fn = workdir 'linux/drivers/pinctrl/pinctrl-bcm2708.c'
    File.write fn, s
    # insert new probe funtion
    probe = File.read findfile 'files/pinctrl-bcm2708-probe.c'
    insert_before fn, 'static int bcm2708_pinctrl_remove', probe
    insert_before fn, '#include <linux/of_irq.h>', "#include <linux/of_gpio.h>\n"
    insert_after fn, ' * Copyright (C) 2012 Chris Boot, Simon Arlott, Stephen Warren', """
 * Copyright (C) 2013 Noralf Tronnes
 *
 * This driver is copied from pinctrl-bcm2835.c"""
    insert_after fn, 'MODULE_AUTHOR("Chris Boot, Simon Arlott, Stephen Warren', ', Noralf Tronnes'

    # add debug for pinconf_set
    insert_before fn, '		if (param != BCM2708_PINCONF_PARAM_PULL)', <<'EOM'
		dev_dbg(pc->dev, "configure pin %u (%s) = %04X\n", pin, bcm2708_gpio_groups[pin], arg);
EOM
  end

  # Add config option for Device Tree with MACH_BCM2708
  #   arch/arm/mach-bcm2708/Kconfig
  target :patch do
    Readme.patch "* Add Device Tree support BCM2708_DT\n"
    insert_before workdir('linux/arch/arm/mach-bcm2708/Kconfig'), 'endmenu', <<EOM

config BCM2708_DT
	bool "Use Device Tree"
	depends on MACH_BCM2708
	default n
	select USE_OF
	select COMMON_CLK
	select COMMON_CLK_DEBUG
	select BCM2708_GPIO
	select PINCTRL
	select PINCTRL_BCM2708
	help
	  Device Tree and pinctrl support

EOM
  end

  # Copy Device Tree files
  #   arch/arm/boot/dts/{*.dtsi,*.dts}
  target :patch do
    d = File.dirname findfile 'files/bcm2708-rpi-b.dts'
    sh "cp -v #{d}/*.dtsi #{d}/*.dts #{workdir 'linux/arch/arm/boot/dts/'}"
    insert_before workdir('linux/arch/arm/boot/dts/Makefile'), 'dtb-$(CONFIG_ARCH_BCM2835)', "dtb-$(CONFIG_BCM2708_DT) += bcm2708-rpi-b.dtb\n"
    insert_before workdir('linux/arch/arm/boot/dts/Makefile'), 'dtb-$(CONFIG_ARCH_BCM2835)', "dtb-$(CONFIG_BCM2708_DT) += bcm2708-rpi-b-test.dtb\n"
  end

  # Add Device Tree support to board file
  #   arm/mach-bcm2708/bcm2708.c
  target :patch do
    fn = workdir 'linux/arch/arm/mach-bcm2708/bcm2708.c'
    insert_before fn, '#include <linux/version.h>', """
#include <linux/clk/bcm2835.h>
#include <linux/of_platform.h>
"""
    insert_before fn, 'void __init bcm2708_init(void)', <<'EOM'
#if defined(CONFIG_BCM2708_DT)
static void __init bcm2708_dt_init(void)
{
	int ret;

	bcm2835_init_clocks();

	ret = of_platform_populate(NULL, of_default_bus_match_table, NULL, NULL);
	if (ret) {
		early_printk("bcm2708: of_platform_populate failed: %d\n", ret);
		pr_emerg("bcm2708: of_platform_populate failed: %d\n", ret);
		BUG();
	}
}
#else
static void __init bcm2708_dt_init(void) { }
#endif /* CONFIG_BCM2708_DT */


EOM
    insert_before fn, '#if defined(CONFIG_BCM_VC_CMA)', """
	bcm2708_dt_init();

"""
    insert_before fn, 'MACHINE_START', <<EOM
static const char * const bcm2708_compat[] = {
	"brcm,bcm2708",
	NULL
};

EOM
    insert_before fn, 'MACHINE_END', "	.dt_compat = bcm2708_compat,\n"
  end

  # Build bcm2835 clock driver
  #   drivers/clk/Makefile
  target :patch do
    fn = workdir 'linux/drivers/clk/Makefile'
    insert_before fn, 'obj-$(CONFIG_ARCH_BCM2835)', "obj-$(CONFIG_BCM2708_DT)	+= clk-bcm2835.o\n"
  end

  # Don't export clock functions since we use the Common Clock framework
  #   arch/arm/mach-bcm2708/clock.c
  target :patch do
    fn = workdir 'linux/arch/arm/mach-bcm2708/clock.c'
    insert_before fn, 'int clk_enable(struct clk *clk)', "#ifndef CONFIG_BCM2708_DT\n"
    File.open(fn, 'a') { |f| f.write "#endif\n" }
  end

  # Add Device Tree IRQ mapping
  #   arch/arm/mach-bcm2708/armctrl.c
  patch 'armctrl.patch'

  # Make drivers DT aware and don't register devices for them in bcm2708.c 
  #   drivers/i2c/busses/i2c-bcm2708.c
  #   drivers/spi/spi-bcm2708.c
  patch 'dt-enable-drivers.patch'
  target :patch do
    fn = workdir 'linux/arch/arm/mach-bcm2708/bcm2708.c'
    Readme.patch "* Disable spi0, i2c0 and i2c1 devices in #{fn}\n"
    replace fn, "	bcm_register_device(&bcm2708_spi_device);\n", ''
    replace fn, "	bcm_register_device(&bcm2708_bsc0_device);\n", ''
    replace fn, "	bcm_register_device(&bcm2708_bsc1_device);\n", ''
    Readme.patch "* i2c: bcm2708: Linking platform nodes to adapter nodes\n"
    insert_before workdir('linux/drivers/i2c/busses/i2c-bcm2708.c'), '	adap->nr = pdev->id;', "	adap->dev.of_node = pdev->dev.of_node;\n"
  end

  # Make i2c-bcm2835 and spi-bcm2835 choosable
  target :patch do
    Readme.patch "* Make it possible to choose I2C_BCM2835 and SPI_BCM2835 with MACH_BCM2708\n"
    replace workdir('linux/drivers/i2c/busses/Kconfig'), 'depends on ARCH_BCM2835', 'depends on ARCH_BCM2835 || MACH_BCM2708'
    replace workdir('linux/drivers/spi/Kconfig'), 'depends on ARCH_BCM2835', 'depends on (ARCH_BCM2835 || MACH_BCM2708)'
  end
  # for 3.12
  patch 'i2c--bcm2835--Linking-platform-nodes-to-adapter-nodes.patch'

  config ['BCM2708_DT', 'DYNAMIC_DEBUG', 'PROC_DEVICETREE'], :enable

  # Let Device Tree handle SPI devices
  config 'BCM2708_SPIDEV', :disable

  target :kbuild do
    post_install <<EOM
cp "${FW_REPOLOCAL}/zImage" "${FW_PATH}/"

EOM
	end

  target :build do
    dst = workdir 'out'
    ksrc = workdir 'linux'
    cp(ksrc + "/arch/arm/boot/zImage", dst)
    sh "cp #{ksrc}/arch/arm/boot/dts/*.dtb #{dst}"
  end
end
